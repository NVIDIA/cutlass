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

"""EFC framework core: the `VariadicParameters`, `JIT` and `Kernel`
companion base classes, and the outer `EFC` class.  `Tensor` /
`_RemapModesAccessor` (from `_tensor.py`) and `Configuration` (from
`_configuration.py`) are exposed on the `EFC` namespace via class-body
`ClassVar` aliases (`EFC.Tensor`, `EFC.Configuration`, ...).

EFC (Epilogue Fusion Codegen) lets a user write a single Python
function describing a fused kernel epilogue; the framework
re-invokes that function under multiple phases
(`EFC.Phase.ParameterAnalysis`, `.ThreadOperation`,
`.PyTorchEvaluation`) to synthesize the CuTe DSL code and a
reference implementation from one description.

**Contract on user epilogue functions:** the user function is
called multiple times with different `EFC.Configuration`
implementations (one per phase). It must be **pure across phase
re-executions** — no side effects, no control flow conditional
on state that differs between phases, and only CuTe DSL
primitives or `efc_config.*` helpers for arithmetic. Violations
surface as phase-specific bugs that are hard to diagnose.
"""

# This is not to use module annotations from a future version but to change the type system to postpone the evaluation of annotations,
# about forward declaration and lazy type checking.
# See https://docs.python.org/3/library/__future__.html#future__.annotations and https://peps.python.org/pep-0563/.
from __future__ import annotations

import dataclasses
import inspect
import typing

import cutlass

from ._configuration import Configuration
from ._helpers import (
    NEWLINE_AND_TAB,
    TAB,
    log,
    trace_in_mlir,
)
from ._phase import Phase
from ._tensor import Tensor, _RemapModesAccessor

"""
CUTLASS EFC Framework
"""


class VariadicParameters:
    """Minimal mixin wrapper for variadic parameters for @cute.jit/@cute.kernel
    functions taking advantage that the DSL can ingest a recursive
    combination of tuples and lists."""

    class _UnassignedArgument:
        """Sentinel class to detect uninitialized arguments."""

        def __repr__(self):
            return "<UnassignedArgument>"

    def __init__(self, efc, parameter_names):
        # Local shortcuts to the EFC instance and the operator it wraps.
        self.efc = efc
        self.operator = efc.operator
        self._create_parameter_class(parameter_names)
        self._init_args_with_unassigned()
        log(f"Initial {self.arg = }")

    def _create_parameter_class(self, parameter_names):
        """Create a dataclass with the given parameter names.

        The dataclass uses __slots__ to avoid assigning wrong arguments by error
        and has __getitem__/__setitem__ methods for dict-like access.
        """
        fields = [(name, typing.Any) for name in parameter_names]
        self._parameter_class = dataclasses.make_dataclass(
            "Parameter", fields, slots=True
        )
        self._add_item_accessors()

    def _add_item_accessors(self):
        """Add __getitem__ and __setitem__ methods to the parameter class.

        This allows accessing attributes by name, e.g., arg["a"] or parameter["b"].
        """

        def getitem(self, name):
            """Access the dataclass attribute by name."""
            return getattr(self, name)

        def setitem(self, name, value):
            """Set the dataclass attribute by name."""
            setattr(self, name, value)

        self._parameter_class.__getitem__ = getitem
        self._parameter_class.__setitem__ = setitem

    def _init_args_with_unassigned(self):
        """Initialize all arg attributes to _UnassignedArgument sentinel.

        This ensures any forgotten field will trigger a noticeable error.
        """
        self.arg = self._parameter_class(
            *(
                [self._UnassignedArgument]
                * len(dataclasses.fields(self._parameter_class))
            )
        )

    def pack_arguments(self, *args, **kwargs):
        """Pack the arguments as a tuple to pass them through a
        @cute.jit/@cute.kernel call.

        If some arguments are provided, pack them and set self.arg, otherwise
        just use the self.arg object by default.

        Return a tuple or None as an interface object since a
        @cute.jit/@cute.kernel can ingest a recursive combination of tuples and
        lists.
        """
        if args or kwargs:
            # Override the current argument object from the provided arguments, if any.
            self.arg = self._parameter_class(*args, **kwargs)
        # dataclasses.astuple(self.arg) breaks because it is recursive and
        # applies a deepcopy incompatible with the DSL magic. Just generate 1
        # level of tuple of object references.
        r = tuple(self.arg[f.name] for f in dataclasses.fields(self.arg))
        log(
            f"pack_arguments {args = }{NEWLINE_AND_TAB}{kwargs = }{NEWLINE_AND_TAB}{self.arg = }{NEWLINE_AND_TAB}{r = }"
        )
        # The DSL does not accept an empty tuple but can handle None. So
        # remap to None in that case.
        if not r:
            return None
        return r

    def unpack_parameters(self, p: tuple):
        """Unpack the parameters inside a @cute.jit/@cute.kernel function.

        Assign all the self.parameter attributes."""
        # Do the opposite mapping of None to an empty tuple to have the
        # parameter constructor happy.
        if p is None:
            p = ()
        # Instantiate the dataclass holding the parameters from the
        # individual parameter values.
        self.parameter = self._parameter_class(*p)
        log(f"unpack_parameters {p = }{NEWLINE_AND_TAB}{self.parameter = }")

    def instantiate_args(self):
        """Create an arg attribute from the Parameter class to be used
        as an alternative way to pass the arguments instead of using an
        explicit pack_arguments().

        All the arg attributes are initialized to a noticeable name so that
        any forgotten field will trigger an error."""
        self._init_args_with_unassigned()

    def extend_parameters(self, names):
        """Extend the dataclass with new field names.

        This creates a new dataclass that inherits all existing fields and adds
        the new ones. The existing arg/parameter values are preserved and new
        fields are initialized to _UnassignedArgument.

        Args:
            names: List of new parameter names to add to the dataclass.
        """
        if not names:
            return

        # Get existing field names and values from arg.
        existing_fields = [f.name for f in dataclasses.fields(self._parameter_class)]
        existing_arg_values = [self.arg[name] for name in existing_fields]

        # Also get existing parameter values if parameter exists.
        has_parameter = hasattr(self, "parameter")
        if has_parameter:
            existing_param_values = [self.parameter[name] for name in existing_fields]

        # Create new dataclass with combined fields.
        self._create_parameter_class(existing_fields + list(names))
        log(f"Extended parameters {dataclasses.fields(self._parameter_class) = }")

        # Reconstruct the arg object with existing values and new unassigned
        # fields.
        new_arg_values = existing_arg_values + [self._UnassignedArgument] * len(names)
        log(f"Extended parameters {new_arg_values = }")
        self.arg = self._parameter_class(*new_arg_values)

        # Also reconstruct parameter if it existed.
        if has_parameter:
            new_param_values = existing_param_values + [self._UnassignedArgument] * len(
                names
            )
            self.parameter = self._parameter_class(*new_param_values)

        log(f"Extended parameters with {names}, now {self.arg = }")


class JIT(VariadicParameters):
    """Handle Python/@cute.jit and its boundaries with Host."""

    # All the following customization functions should go somewhere else in
    # the long term, as part of a refactoring similar to CUTLASS
    # collective/main loop/epilogue...

    # The following foreach_... functions are some refinement of the EFC
    # ones to handle more precisely the broadcast tensors for example.

    def get_argument_or_remapped_tensor(self, name):
        """A remapped tensor is not passed as a parameter but synthesized and stored in self.remapped_tensors."""
        if tensor := self.remapped_tensors.get(name):
            return tensor
        return self.parameter[name]

    def get_remapped_tensor_or_itself(self, name):
        """For a remapped tensor name, return the remapped tensor view, otherwise return the tensor itself."""
        if self.efc.parameter_attributes[name].mapped_source:
            return self.remapped_tensors[name]
        return self.parameter[name]

    def foreach_tensor(self, function):
        """Execute the given function for each supplemental tensor,
        providing the tensor object from the JIT parameters."""

        def wrapper(tensor_name, attributes):
            function(
                self.get_argument_or_remapped_tensor(tensor_name),
                tensor_name,
                attributes,
            )

        self.efc.foreach_tensor(wrapper)

    def foreach_non_degenerate_tensor(self, function):
        """Execute the given function for each supplemental tensor,
        providing the tensor object from the JIT parameters. Skip the tensor
        if it is a degenerate case as scalar in broadcast."""

        def wrapper(tensor_name, attributes):
            if not attributes.degenerate_to_scalar:
                function(
                    self.get_argument_or_remapped_tensor(tensor_name),
                    tensor_name,
                    attributes,
                )

        self.efc.foreach_tensor(wrapper)

    def foreach_remapped_tensor(self, function):
        """Execute the given function for each remapped tensor,
        providing the remapped tensor object if any."""

        def wrapper(tensor_name, attributes):
            if not attributes.degenerate_to_scalar:
                # Call the function only if it ends up as a real tensor.
                function(self.remapped_tensors[tensor_name], tensor_name, attributes)

        self.efc.foreach_remapped_tensor(wrapper)

    def foreach_remapped_tensor_as_scalar(self, function):
        """Execute the given function for each remapped tensor, providing
        the remapped tensor object only if it degenerates as a scalar
        because all the modes are broadcast."""

        def wrapper(tensor_name, attributes):
            if attributes.degenerate_to_scalar:
                # Call the function only if it ends up as a scalar.
                function(self.remapped_tensors[tensor_name], tensor_name, attributes)

        self.efc.foreach_remapped_tensor(wrapper)

    def foreach_argument(self, function):
        """Execute the given function for each supplemental argument,
        providing the parameter value from the JIT parameters.

        Note that remapped tensors are not direct parameters but are
        synthesized and accessed via self.remapped_tensors."""

        def wrapper(name, attributes):
            log(f"JIT.foreach_argument {name = }")
            function(
                self.get_argument_or_remapped_tensor(name),
                name,
                attributes,
            )

        self.efc.foreach_argument(wrapper)

    @trace_in_mlir
    def handle_remapping(self):
        # Lazy import to avoid a circular dependency: `_remap.py` imports
        # `log` / `if_info` from this module, which is fine at call time
        # but not at module-load time.
        from ._remap import remap_modes

        # Track the remapped tensors by their names.
        self.efc.jit.remapped_tensors = {}

        def f(tensor_name, attributes):
            log(f"handle_remapping of tensor {tensor_name}")
            log(f"{TAB}mapped_source {attributes.mapped_source}")
            log(f"{TAB}source_mode_map {attributes.source_mode_map}")
            self.efc.jit.remapped_tensors[tensor_name] = remap_modes(
                source=self.efc.jit.parameter[attributes.mapped_source],
                target_shape=self.efc.output_shape,
                source_mode_map=attributes.source_mode_map,
                info_tensor_name=tensor_name,
                info_source_name=attributes.mapped_source,
            )
            log(
                f"{TAB}self.efc.jit.remapped_tensors[{tensor_name}] = {self.efc.jit.remapped_tensors[tensor_name]}"
            )

        self.efc.foreach_remapped_tensor(f)

    @trace_in_mlir
    def record_tensor_dtypes(self):
        """It does not seem that the tma_tensor and tma_atom carry over the
        element type, so, store it here for later use."""
        self.tensor_dtype = {}

        def f(tensor, tensor_name, attributes):
            self.tensor_dtype[tensor_name] = tensor.element_type

        self.foreach_tensor(f)

    @trace_in_mlir
    def written_tensor_name_with_bigger_element_type(self):
        """The type of the written tensor is used to compute a lot of
        implementation details about tiling and so on in the kernel.

        The compilation phase has already checked that there is at least 1
        written tensor name.

        Return the name of the written tensor with the biggest
        element_type.

        """
        return max(
            (tensor_name for tensor_name in self.efc.written_tensor_names),
            key=lambda tensor_name: self.tensor_dtype[tensor_name].width,
        )

    @trace_in_mlir
    def read_tensor_name_with_bigger_element_type(self):
        """The type of the read tensor is used to compute a lot of
        implementation details about tiling and so on in the kernel. Return
        the name of the read tensor with the biggest element_type, or None
        if there is no read tensor."""
        if self.efc.read_tensor_names:
            return max(
                (tensor_name for tensor_name in self.efc.read_tensor_names),
                key=lambda tensor_name: self.tensor_dtype[tensor_name].width,
            )
        return None

    @trace_in_mlir
    def smem_size_in_bytes_of_read_tensors(self):
        """Get the contribution in a smem pipeline stage from the tensors
        loaded in the EFC."""
        log(
            f"JIT.smem_size_in_bytes_of_read_tensors {self.smem_size_of_read_tensors = }"
        )
        return self.smem_size_of_read_tensors

    @trace_in_mlir
    def smem_size_in_bytes_of_written_tensors(self):
        """Get the contribution in a smem pipeline stage from the tensors
        stored in the EFC."""
        log(
            f"JIT.smem_size_in_bytes_of_written_tensors {self.smem_size_of_written_tensors = }"
        )
        return self.smem_size_of_written_tensors

    @trace_in_mlir
    def smem_size_in_bytes_of_reduce_tensors(self):
        """Get the fixed (non-staged) SMEM contribution from the
        per-warp scratch buffers used by ``Tensor.reduce``
        destinations.  Unlike the read/written totals, this is *not*
        multiplied by a pipeline stage count -- one scratch buffer
        is allocated per reduce destination for the whole kernel."""
        log(
            f"JIT.smem_size_in_bytes_of_reduce_tensors {self.smem_size_of_reduce_tensors = }"
        )
        return self.smem_size_of_reduce_tensors


class Kernel(VariadicParameters):
    """Handle kernel part and @cute.jit/@cute.kernel boundaries."""

    def foreach_tensor(self, function):
        """Execute the given function for each supplemental tensor, skipping
        the degenerate scalar broadcast cases."""

        def wrapper(tensor_name, attributes):
            if not attributes.degenerate_to_scalar:
                function(
                    tensor_name,
                    attributes,
                )

        self.efc.foreach_tensor(wrapper)

    def foreach_read_tensor(self, function):
        """Execute the given function for each supplemental read tensor,
        skipping the degenerate scalar broadcast cases."""

        def wrapper(tensor_name, attributes):
            if not attributes.degenerate_to_scalar:
                function(
                    tensor_name,
                    attributes,
                )

        self.efc.foreach_read_tensor(wrapper)

    def foreach_written_tensor(self, function):
        """Execute the given function for each supplemental written tensor,
        skipping the degenerate scalar broadcast cases."""

        def wrapper(tensor_name, attributes):
            if not attributes.degenerate_to_scalar:
                function(
                    tensor_name,
                    attributes,
                )

        self.efc.foreach_written_tensor(wrapper)


# Type variables that parameterize ``EFC`` over the concrete
# host-side (``JIT``) and device-side (``Kernel``) companion classes
# a given operator supplies.  An operator typically annotates its
# stored ``EFC`` instance with the concrete classes
# (``common_efc.EFC[_DenseGemmEFCJIT, _DenseGemmEFCKernel]``), which
# lets static analysers resolve ``self.efc.jit.<method>`` and
# ``self.efc.kernel.<method>`` calls instead of falling back to
# ``Any``.
JITT = typing.TypeVar("JITT", bound="JIT")
KernelT = typing.TypeVar("KernelT", bound="Kernel")

# Covariant variants of the same TypeVars, used as parameters of
# ``_OperatorProtocol`` below.  Because the Protocol reads its
# companion-class slots only through read-only ``@property``
# getters, declaring covariance here matches the actual usage --
# while the plain ``JITT`` / ``KernelT`` above remain invariant
# so ``EFC.jit`` / ``EFC.kernel``, which are mutable, stay
# well-formed.  The Protocol can still be parameterized with
# either the invariant or covariant TypeVars from a use-site,
# since covariance only loosens the substitution rules.
JITT_co = typing.TypeVar("JITT_co", bound="JIT", covariant=True)
KernelT_co = typing.TypeVar("KernelT_co", bound="Kernel", covariant=True)

# Module-level aliases of the framework's base companion classes,
# used as the default value of ``EFC.JIT`` / ``EFC.Kernel``.  The
# aliases dodge the name shadow that would otherwise happen inside
# ``class EFC`` (where ``JIT`` and ``Kernel`` become class attributes)
# while keeping the analyser-visible binding inside the class body
# rather than as a post-class ``EFC.JIT = JIT`` reassignment.
_BaseJIT = JIT
_BaseKernel = Kernel


class _OperatorProtocol(typing.Protocol[JITT_co, KernelT_co]):
    """The slice of an operator's surface that the EFC framework reads.

    Concrete operator classes (e.g. ``DenseGemmEFC``) satisfy this
    structurally -- they expose attributes of the matching shape --
    so framework code can type ``self.operator.JIT`` /
    ``self.efc.operator.Kernel`` / ``self.efc.operator.epi_dtype``
    / ``self.efc.operator.epilogue_warp_id`` precisely instead of
    falling back to ``Any``.

    Every other operator-specific attribute (``mma_tiler``,
    ``d_layout``, etc.) stays outside this contract on purpose: the
    operator's device-side companions inherit ``self.operator`` from
    ``VariadicParameters`` (intentionally left untyped, so it stays
    ``Any``), which means kernel-side accesses such as
    ``self.operator.mma_tiler`` keep working without having to
    enumerate the full operator API here.  Add a member below only
    when a piece of *framework* code (not an operator's device-side
    method) starts reading it through ``self.operator`` or
    ``self.efc.operator``.

    Each member is declared as a read-only ``@property`` rather than
    a plain attribute: in ``typing.Protocol`` a writable attribute is
    invariant in its type, which would reject otherwise-valid
    concrete attributes whose inferred type is narrower than the
    declared one (e.g. ``tuple[Literal[0, 1, 2, 3]]`` from a literal
    ``(0, 1, 2, 3)`` against ``tuple[int, ...]``).  Read-only
    properties express the framework's actual usage and give the
    matching covariance, while still matching structurally against
    concrete attribute, class attribute, or property implementations
    on the operator side.
    """

    @property
    def JIT(self) -> type[JITT_co]: ...

    @property
    def Kernel(self) -> type[KernelT_co]: ...

    @property
    def epi_dtype(self) -> type[cutlass.Numeric]: ...

    @property
    def epilogue_warp_id(self) -> tuple[int, ...]: ...


class EFC(typing.Generic[JITT, KernelT]):
    """Epilogue Fusion Configuration.

    Generic over the concrete companion classes the operator
    supplies: ``JITT`` is the host-side ``EFC.JIT`` subclass and
    ``KernelT`` is the device-side ``EFC.Kernel`` subclass.  The
    framework instantiates them lazily during ``compile()`` and
    kernel codegen via the operator-class lookup
    (``self.operator.JIT(...)`` / ``self.operator.Kernel(...)``);
    annotating the EFC instance with the parameterized form
    (e.g. ``common_efc.EFC[_DenseGemmEFCJIT, _DenseGemmEFCKernel]``)
    is what gives editors a precise type for ``self.efc.jit`` and
    ``self.efc.kernel`` after they are bound.
    """

    # User-facing aliases reachable through the ``EFC`` namespace
    # (``EFC.JIT``, ``EFC.Kernel``, ``EFC.Phase``, ``EFC.Tensor``,
    # ``EFC._RemapModesAccessor``, ``EFC.Configuration``).  Operator
    # subclasses inherit through these spellings (for example
    # ``class _DenseGemmEFCJIT(common_efc.EFC.JIT)``); user epilogue
    # code uses ``EFC.Phase.<...>`` etc.
    JIT: typing.ClassVar[type[JIT]] = _BaseJIT  # noqa: F811 — class-level alias.
    Kernel: typing.ClassVar[type[Kernel]] = _BaseKernel  # noqa: F811 — class-level alias.
    Phase: typing.ClassVar[type[Phase]] = Phase  # noqa: F811 — class-level alias.
    Tensor: typing.ClassVar[type[Tensor]] = Tensor  # noqa: F811 — class-level alias.
    _RemapModesAccessor: typing.ClassVar[type[_RemapModesAccessor]] = (  # noqa: F811
        _RemapModesAccessor
    )
    Configuration: typing.ClassVar[type[Configuration]] = (  # noqa: F811
        Configuration
    )

    # Instance attributes set during the EFC lifecycle.  Declared at
    # the class level so type-checkers can follow them even though
    # the actual assignments happen outside ``__init__``:
    #   * ``operator`` is bound in ``__init__`` below; its declared
    #     type is the framework-side contract documented on
    #     ``_OperatorProtocol``, which is what lets calls such as
    #     ``self.operator.JIT(...)`` and
    #     ``self.efc.operator.Kernel(...)`` type-check;
    #   * ``jit`` is bound in ``compile()`` (this file);
    #   * ``kernel`` is bound in the operator's
    #     ``create_supplemental_arguments_for_kernel`` (see the
    #     concrete operator's ``JIT`` companion).
    operator: _OperatorProtocol[JITT, KernelT]
    jit: JITT
    kernel: KernelT

    def __init__(
        self,
        operator: _OperatorProtocol[JITT, KernelT],
        epilogue_function_configuration,
    ):
        """Construct an EFC instance.

        :param operator: a concrete operator instance (e.g. a
            ``DenseGemmEFC``) that exposes nested ``JIT`` and ``Kernel``
            classes specialising the host- and device-side companions of
            this framework with operator-specific behaviour.  EFC will
            instantiate them at the right points in the pipeline.
            ``_OperatorProtocol`` formalises the small slice of the
            operator's surface the framework actually reads.
        """
        self.operator = operator
        self.epilogue_function_configuration = epilogue_function_configuration
        self.analyze_epilogue(epilogue_function_configuration)

    def analyze_epilogue(self, epilogue_function_configuration):
        """Analyze the epilogue configuration function to extract its parameter
        names."""
        sig = inspect.signature(epilogue_function_configuration)
        names = list(sig.parameters)
        # Require the first parameter to be named "efc_config". This is very
        # intrusive but at the same time some people got confused when they
        # forgot this parameter.
        if names[0] != "efc_config":
            raise RuntimeError(
                "The epilogue configuration function must take efc_config as an argument"
            )

        # Keep all the argument names but the first "efc_config" one.
        self.epilogue_parameter_names = names[1:]
        log(f"{self.epilogue_parameter_names = }")

    def compile(self, *supplemental_arguments):
        """Compile with all the arguments to know the types during compilation
        while hiding the epilogue details."""
        if len(supplemental_arguments) != len(self.epilogue_parameter_names):
            raise ValueError(
                f"Expected {len(self.epilogue_parameter_names)} supplemental arguments "
                f"({', '.join(self.epilogue_parameter_names)}), got {len(supplemental_arguments)}."
            )
        # Update the active epilogue instance to use the new Parameter class
        self.analyze_epilogue_with_arguments(supplemental_arguments)
        # Pick up the operator's nested ``JIT`` class -- concrete
        # operators provide their own host-side companion via
        # ``operator.JIT`` (a subclass of ``EFC.JIT``).
        self.jit = self.operator.JIT(self, self.epilogue_parameter_names)
        if not self.written_tensor_names:
            raise NotImplementedError(
                "The epilogue requires at least one written tensor to do something useful."
            )

    def analyze_epilogue_with_arguments(self, supplemental_arguments):
        # Keep track of the usage attributes of the tensors by their names.
        self.parameter_attributes = {}
        log(f"{self.analyze_epilogue_with_arguments}:")
        for name, a in zip(self.epilogue_parameter_names, supplemental_arguments):
            log(f"{name = } {a = }, {type(a) = }")
            self.parameter_attributes[name] = Tensor.ParameterAttributes(
                is_tensor=isinstance(a, cutlass.cute.Tensor)
            )

        # Evaluate the epilogue function for parameter analysis
        self.specialized_epilogue(Phase.ParameterAnalysis)()
        log(
            f"tensor attributes = {NEWLINE_AND_TAB}{NEWLINE_AND_TAB.join([name + ':' + TAB + str(attributes) for name, attributes in self.parameter_attributes.items()])}"
        )
        # Keep track of all the epilogue tensor use cases per name:
        self.used_tensor_names = []
        self.read_tensor_names = []
        self.written_tensor_names = []
        self.remapped_tensor_names = []
        for name, attributes in self.parameter_attributes.items():
            attributes = self.parameter_attributes[name]
            if not attributes.is_tensor:
                continue
            if attributes.is_read or attributes.is_written:
                self.used_tensor_names.append(name)
            if attributes.is_read:
                self.read_tensor_names.append(name)
            if attributes.is_written:
                self.written_tensor_names.append(name)
            if attributes.mapped_source:
                self.remapped_tensor_names.append(name)
        log(f"{TAB}{self.used_tensor_names = }")
        log(f"{TAB}{self.read_tensor_names = }")
        log(f"{TAB}{self.written_tensor_names = }")
        log(f"{TAB}{self.remapped_tensor_names = }")

        # Validate reduce destinations: each one must resolve to a
        # single-element source tensor.  The user-facing API already
        # requires an all-``:`` remap subscript (so the *expected*
        # source rank is 0), but the *actual* tensor backing the
        # parameter could be larger; here we additionally check that
        # its total element count is 1, so a multi-element buffer
        # cannot silently land in the atomic-write path (the kernel
        # would only ever touch index 0 of it).
        #
        # We read the size from ``.shape`` (a plain tuple of ints
        # exposed by the runtime-side ``cutlass.cute.Tensor``)
        # rather than ``cutlass.cute.size(arg.layout)``: at this
        # point the supplemental argument is still the host-side
        # tensor object that ``cute_tensor_like`` produced, and
        # ``.layout`` is a JIT-only property -- it raises
        # ``NotImplementedError("layout property is not supported
        # in runtime")`` here.  ``math.prod(())`` is ``1``, which
        # handles the rank-0 case correctly.
        import math

        name_to_arg = dict(zip(self.epilogue_parameter_names, supplemental_arguments))
        for name, attributes in self.parameter_attributes.items():
            if attributes.reduce_op is None:
                continue
            source_arg = name_to_arg[attributes.mapped_source]
            if not isinstance(source_arg, cutlass.cute.Tensor):
                raise TypeError(
                    f"Tensor.reduce() destination remapped from "
                    f"'{attributes.mapped_source}' is not a cute.Tensor "
                    f"(got {type(source_arg).__name__}); scalar "
                    f"reduction requires a single-element tensor."
                )
            source_size = math.prod(source_arg.shape)
            if source_size != 1:
                raise ValueError(
                    f"Tensor.reduce() destination remapped from "
                    f"'{attributes.mapped_source}' has size "
                    f"{source_size}; only single-element destinations "
                    f"are currently supported."
                )

    def specialized_epilogue(self, phase: Phase, *args):
        """Construct a configuration of the epilogue specialized for a given
        phase. The arguments are opaque and depend on the actual phase use."""
        return Configuration(self, phase, *args)

    def foreach_argument(self, function):
        """Execute the given function for each supplemental argument of the epilogue."""
        for name, attributes in self.parameter_attributes.items():
            function(name, attributes)

    def foreach_tensor(self, function):
        """Execute the given function for each supplemental tensor."""
        for tensor_name in self.used_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_read_tensor(self, function):
        """Execute the given function for each supplemental read tensor."""

        for tensor_name in self.read_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_written_tensor(self, function):
        """Execute the given function for each supplemental written tensor."""

        for tensor_name in self.written_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def foreach_remapped_tensor(self, function):
        """Execute the given function for each supplemental remapped tensor."""

        for tensor_name in self.remapped_tensor_names:
            attributes = self.parameter_attributes[tensor_name]
            function(tensor_name, attributes)

    def evaluate_on_cpu(self, matrix_multiplication_ref, args: tuple):
        """Evaluate the epilogue fusion configuration function on CPU for
        validation using the precomputed matrix multiplication result.

        Use PyTorch for now but could be whatever."""
        # A mapping from argument names to their values, scalars or torch.Tensor.
        epilogue_args = dict(zip(self.epilogue_parameter_names, args))
        # Evaluate the epilogue with PyTorch. The tensor arguments which are
        # stored are also evaluated and this is how some results are returned.
        self.specialized_epilogue(
            Phase.PyTorchEvaluation,
            matrix_multiplication_ref,
            epilogue_args,
        )()
