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
from __future__ import annotations

import functools
import inspect
import warnings
from abc import ABC, abstractmethod
from typing import TYPE_CHECKING, ClassVar, final

import cuda.bindings.driver as cuda

from cutlass.operators.arch import TargetSm
from cutlass.operators.device_properties import (
    DeviceProperties,
    get_default_device_properties,
)
from cutlass.operators.status import Status
from cutlass.operators.utils.device import device_or_env_target_sm
from cutlass.operators.workspace import AllocationRequirement, Workspace

if TYPE_CHECKING:
    from collections.abc import Callable, Sequence

    from cutlass.operators.arguments import EpilogueArgumentsBase, RuntimeArguments
    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.metadata import OperatorMetadata
    from cutlass.operators.typing import TensorLike


class Operator(ABC):
    """Central class that provides a uniform interface over DSL kernels.

    An ``Operator`` is Operator API's central interface of instantiating,
    finding, and executing DSL kernels.
    A **kernel** is the raw DSL code that does the computation; an
    **Operator** wraps a kernel and exposes a uniform interface to it.
    Each Operator subclass fills in the kernel-agnostic interface with
    kernel-specific implementations for:

    * correctly extracting arguments and compile/run the kernel
    * generating instances of the Operator
    * exposing the kernel's properties via ``OperatorMetadata``

    Typically, DSL kernels are written as classes that are parameterized (e.g. by
    operand data types, tensor layouts, tile shapes, etc.) into a family
    of related kernel configurations, much like a "template". Instantiating &
    compiling a kernel class with concrete parameters produces a single runnable kernel.

    Likewise, an ``Operator`` subclass represents a family of parametrized kernels,
    wrapped in the uniform interface. Each *instance* of that subclass represents
    one fully-specified kernel configuration.
    The subclass is responsible for generating valid configurations of this family from the
    design space. All features that distinguish one Operator instance from another are
    exposed via a read-only :attr:`metadata`.
    """

    supported_args_type: ClassVar[type[RuntimeArguments]]
    """The subtype of ``RuntimeArguments`` that this Operator supports.

    This is used by providers to filter operator classes before calling ``generate_operators()``.
    Subclasses must override this, failing which an error is raised when the subclass is defined.
    """

    designed_for_min_cc: ClassVar[int]
    """Minimum compute capability that this operator class is designed for.

    It is assumed that an Operator cannot run on an architecture with compute capability
    older than this.
    It indicates a broad class-level minimum, meant for rough filtering.
    However, it does not imply that the Operator can run on every newer architecture --
    ``operator.metadata.supported_targets`` provides finegrained ground-truth information about which
    architectures each Operator instance can run on.
    """

    def __init_subclass__(cls, **kwargs):
        """Validate that the concrete subclass defines required class-level attributes.

        Raises:
            TypeError: If the subclass does not define ``supported_args_type`` or
                ``designed_for_min_cc``.
        """
        super().__init_subclass__(**kwargs)
        if not _run_accepts_device_properties(cls):
            warnings.warn(
                f"{cls.__qualname__}._run uses the deprecated signature without a "
                "'device_properties' parameter. This signature will stop working "
                "in a future release; add the parameter.",
                DeprecationWarning,
                stacklevel=2,
            )
        if inspect.isabstract(cls):
            return

        required_attrs = ["supported_args_type", "designed_for_min_cc"]
        for attr in required_attrs:
            if attr not in cls.__dict__:
                raise TypeError(
                    f"Operator subclass {cls.__name__} must define '{attr}'."
                )

    def __init__(self, metadata: OperatorMetadata):
        self._metadata = metadata

    @property
    def metadata(self) -> OperatorMetadata:
        """The read-only metadata for the operator.

        All features that distinguish one Operator from another (supported operand attributes, design
        choices, supported targets, optional epilogue, ...) are exposed via metadata, and
        can be used for inspection and filtering.
        """
        return self._metadata

    @final
    def supports(
        self, args: RuntimeArguments, target_sm: TargetSm | str | None = None
    ) -> Status:
        """Return whether the operator can be compiled or run with the provided arguments.

        Args:
            args (RuntimeArguments): Arguments with which the operator is to be compiled or run.
            target_sm (TargetSm | str | None): An optional target compute capability to check support for.

        Returns:
            Status: Status indicating whether the operator can be compiled or run with the provided arguments.
        """
        target_sm = TargetSm.ensure(target_sm)
        # Metadata should capture most common checks
        if not (status := self.metadata.supports(args, target_sm=target_sm)):
            return status
        # Additional checks can be implemented in the subclass
        return self._supports(args, target_sm=target_sm)

    @final
    def compile(
        self, args: RuntimeArguments, target_sm: TargetSm | str | None = None
    ) -> CompiledArtifact:
        """Compile the operator for the given arguments and target architecture.

        This is implicitly called by :meth:`run()`, but can also be called explicitly to obtain a ``CompiledArtifact``
        that and passed to :meth:`run()` later.

        Args:
            args (RuntimeArguments): Arguments to compile the operator with. The operator will be compiled to support the types and layouts of tensors in these args, according to any static information present in it (layouts, dtypes, etc.).
            target_sm (TargetSm | str | None): Target compute capability to compile the operator for.

        Returns:
            CompiledArtifact: The compiled artifact.
        """
        target_sm = TargetSm.ensure(target_sm)
        return self._compile(args, target_sm)

    @final
    def run(
        self,
        args: RuntimeArguments,
        compiled_artifact: CompiledArtifact | None = None,
        stream=None,
        workspace: Workspace | TensorLike | None = None,
        assume_supported_args: bool = False,
        device_properties: DeviceProperties | None = None,
    ) -> None:
        """Execute the operator end-to-end with provided arguments.

        Check that args are supported, compile if needed, create a default stream if
        needed, and launch the underlying kernel.

        Args:
            args (RuntimeArguments): Arguments with which to run the operator.
            compiled_artifact (CompiledArtifact | None): Compiled artifact returned from the :meth:`compile()`. If ``None``, the operator will first be compiled.
            stream (cuda.CUstream, torch.cuda.Stream, or other stream-like object, or None): Stream to execute the operator on. If ``None``, the default/null stream ``cuda.CUstream(0)`` is used.
            workspace (Workspace | TensorLike | None): Allocation of workspace at least as large as the workspace size returned from the :meth:`get_workspace_size()`. A tensor is wrapped as ``Workspace(tensor)``. If the operator does not require workspace, this can be ``None``. If a workspace of inappropriate size is provided, the behavior is undefined and the operator may crash.
            assume_supported_args (bool): By default, ``operator.supports(args)`` is called to check if the arguments are supported. If ``True``, this check is skipped.
            device_properties (DeviceProperties | None): Properties of the device to launch with. If ``None``, it uses the cached :func:`get_default_device_properties`.

        Raises:
            ValueError: If ``args`` are unsupported and ``assume_supported_args`` is ``False``.
            TypeError: If ``device_properties`` is given to an operator whose ``_run``
                uses the deprecated signature without it.
        """
        legacy_run = not _run_accepts_device_properties(type(self))
        if legacy_run and device_properties is not None:
            raise TypeError(
                f"{type(self).__qualname__}._run uses the deprecated signature "
                "without a 'device_properties' parameter, so run() cannot pass "
                "device_properties to it. Add the parameter to _run."
            )
        target_sm = (
            compiled_artifact.compiled_for
            if compiled_artifact is not None
            else device_or_env_target_sm()
        )
        if not assume_supported_args and not (
            supports := self.supports(args, target_sm=target_sm)
        ):
            raise ValueError(
                f"Operator does not support the provided arguments: {supports.error}"
            )
        compiled_artifact = compiled_artifact or self.compile(args, target_sm)
        if not stream:
            stream = cuda.CUstream(0)
        if legacy_run:
            # The deprecated signature also predates ``Workspace`` wrapping, so
            # its implementations get the workspace exactly as given.
            return self._run(args, compiled_artifact, stream, workspace)
        if workspace is not None and not isinstance(workspace, Workspace):
            workspace = Workspace(workspace)
        if device_properties is None:
            device_properties = get_default_device_properties()
        return self._run(
            args,
            compiled_artifact,
            stream,
            workspace,
            device_properties=device_properties,
        )

    @final
    def get_workspace_size(self, args: RuntimeArguments) -> AllocationRequirement:
        """Return the workspace requirement for the operator for the given arguments.

        Args:
            args (RuntimeArguments): Arguments to the operator to get the workspace requirement for.

        Returns:
            AllocationRequirement: Requirement describing the size & alignment of the workspace required by the operator.
        """
        return self._get_workspace_size(args)

    @final
    def initialize_workspace(
        self, args: RuntimeArguments, workspace: Workspace
    ) -> None:
        """Initialize the workspace for the operator.

        Args:
            args (RuntimeArguments): Arguments to initialize the workspace for.
            workspace (Workspace): Workspace to initialize.
        """
        return self._initialize_workspace(args, workspace)

    @classmethod
    @final
    def generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArgumentsBase | None = None,
        target_sm: TargetSm | str | None = None,
        args: RuntimeArguments | None = None,
    ) -> Sequence[Operator]:
        """Return a list of all supported operator configurations, optionally constrained to given parameters.

        Args:
            metadata_filter (Callable[[OperatorMetadata], bool]): A Callable
                that takes OperatorMetadata as input and returns a boolean
                indicating if it should be considered for inclusion in results.
                The result is an intersection of operators filtered by the
                callable and by other parameters passed to this method.
            epilogue_args (EpilogueArgumentsBase | None): Optional arguments to
                pass to the operator's epilogue.
            target_sm (TargetSm | str | None): Optionally restrict generation
                to operators compatible with a given TargetSm.
            args (RuntimeArguments | None): Optional arguments to filter
                operators by. If None, all operators are considered.

        Returns:
            Sequence[Operator]: All supported operator configurations.
        """
        target_sm = TargetSm.ensure(target_sm)
        return cls._generate_operators(metadata_filter, epilogue_args, target_sm, args)

    ###
    ### Methods below are to be implemented by concrete classes
    ###

    def _supports(
        self, args: RuntimeArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Perform any additional support checks beyond what metadata captures.

        Subclasses may override this to add checks that cannot be expressed in metadata.
        Ideally, this should be empty and all checks should be captured in the metadata.
        By default, no such checks are performed and the method trivially returns
        ``Status.success()``.

        Args:
            args (RuntimeArguments): Arguments to check support for.
            target_sm (TargetSm | None): An optional target compute capability to check support for.

        Returns:
            Status: Status indicating success, or reason why the operator does not support the provided arguments.
        """
        return Status.success()

    @abstractmethod
    def _compile(
        self, args: RuntimeArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        """Compile the operator."""
        raise NotImplementedError

    @abstractmethod
    def _run(
        self,
        args: RuntimeArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace: Workspace | None = None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        """Launch the underlying kernel for an already-compiled, validated invocation.

        A minimal version of ``run()`` that assumes ``args`` are supported and that a
        valid ``compiled_artifact`` and ``stream`` are provided. Intended to be overridden
        by subclasses as a minimal wrapper around the underlying kernel launch.

        Implementations with device-dependent operands should read them from
        ``device_properties`` rather than querying; the rest ignore it.

        Args:
            args (RuntimeArguments): Arguments to run the operator with. It is assumed that ``operator.supports(args)`` is True.
            compiled_artifact (CompiledArtifact): Compiled artifact returned from the ``compile()`` method.
            stream (cuda.CUstream, torch.cuda.Stream, or other stream-like object): Stream to execute the operator on.
            workspace (Workspace | None): Optional allocation of workspace at least as large as the workspace size returned from the ``get_workspace_size()`` method. If the operator does not require workspace, this can be ``None``. If a workspace of inappropriate size is provided, the behavior is undefined and the operator may crash.
            device_properties (DeviceProperties): Properties of the device to launch with.
        """
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArgumentsBase | None = None,
        target_sm: TargetSm | None = None,
        args: RuntimeArguments | None = None,
    ) -> list[Operator]:
        raise NotImplementedError

    def _get_workspace_size(self, args: RuntimeArguments) -> AllocationRequirement:
        return AllocationRequirement.empty()

    def _initialize_workspace(
        self, args: RuntimeArguments, workspace: Workspace
    ) -> None:
        raise NotImplementedError


@functools.cache
def _run_accepts_device_properties(cls: type[Operator]) -> bool:
    """Return whether ``cls._run`` declares ``device_properties``.

    ``_run(args, compiled_artifact, stream, workspace=None)`` is the deprecated
    signature from before ``device_properties`` existed. ``run()`` calls such
    overrides without it, because passing it in any form raises ``TypeError``.
    """
    params = inspect.signature(cls._run).parameters
    return "device_properties" in params or any(
        p.kind is inspect.Parameter.VAR_KEYWORD for p in params.values()
    )
