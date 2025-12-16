# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

from abc import ABC, abstractmethod
from collections.abc import Callable
from typing import final

import cuda.bindings.driver as cuda

from cutlass_api.arguments import EpilogueArguments, RuntimeArguments
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import KernelMetadata
from cutlass_api.status import Status


class Kernel(ABC):
    """
    Base class for all kernels to be implemented in providers
    """

    @final
    def supports(self, args: RuntimeArguments) -> Status:
        """
        Returns whether the kernel can be compiled or run with the provided arguments

        :param args: arguments with which the kernel is to be compiled or run
        :type args: RuntimeArguments

        :return: Status indicating whether the kernel can be compiled or run with the provided arguments
        :rtype: Status
        """
        # Metadata should capture most common checks
        if not (status := self.metadata.supports(args)):
            return status
        # Additional checks can be implemented in the subclass
        return self._supports(args)

    @abstractmethod
    def compile(
        self, args: RuntimeArguments, cc: int | None = None
    ) -> CompiledArtifact:
        """
        Compiles the kernel.

        For just-in-time compilation, the CompiledArtifact can be used to execute the kernel using run().
        For ahead-of-time compilation, the CompiledArtifact can be saved and restored later to use with run().
        :param args: Arguments to compile the kernel with. These need not be the same arguments as those passed to the run() method.
        :type args: RuntimeArguments
        :param cc: Compute capability of device for which the kernel is to be compiled. For example, if running on H100, this should be set to 90.
        :type cc: int
        """
        raise NotImplementedError

    @final
    def run(
        self,
        args: RuntimeArguments,
        compiled_artifact: CompiledArtifact | None = None,
        stream=None,
        workspace=None,
        assume_supported_args: bool = False,
    ) -> None:
        """
        Executes the kernel end-to-end with provided arguments -- check args are supported, compile if needed, create a default stream if needed, and launch the kernel.

        :param args: Arguments to run the kernel with
        :type args: RuntimeArguments
        :param compiled_artifact: Compiled kernel object returned from the compile() method above. If None, the kernel will first be compiled.
        :type compiled_artifact: CompiledArtifact | None
        :param stream: Stream to execute the kernel on. If not provided, the default/null stream cuda.CUstream(0) is used.
        :type stream: cuda.CUstream, torch.cuda.Stream, or other stream-like object, or None
        :param workspace: Allocation of workspace at least as large as the workspace size returned from the get_workspace_size() method. If the kernel does not require workspace, this can be None.
        If a workspace of inappropriate size is provided, the behavior is undefined and the kernel may crash.
        :type workspace: any | None
        :param assume_supported_args: By default, kernel.supports(args) is called to check if the arguments are supported. If True, this check is skipped.
        :type assume_supported_args: bool
        """
        if not assume_supported_args and not (supports := self.supports(args)):
            raise ValueError(
                f"Kernel does not support the provided arguments: {supports.error}"
            )

        compiled_artifact = (
            self.compile(args) if not compiled_artifact else compiled_artifact
        )
        if not stream:
            stream = cuda.CUstream(0)
        return self._run(args, compiled_artifact, stream, workspace)

    def get_workspace_size(self, args: RuntimeArguments) -> int:
        """
        Returns the size of the workspace required by the kernel in bytes.

        :param args: arguments of the kernel
        :type args: RuntimeArguments

        :return: size of the workspace required by the kernel in bytes
        :rtype: int
        """
        return 0

    def initialize_workspace(self, args: RuntimeArguments, workspace) -> None:
        """
        Initializes the workspace for the kernel.
        :param args: Arguments to initialize the workspace for
        :type args: RuntimeArguments
        :param workspace: Workspace to initialize
        :type workspace: any
        """
        return

    @staticmethod
    @abstractmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["Kernel"]:
        """
        Populates the `kernels` list with all supported kernel configurations
        for the given compute capability and arguments.
        :param metadata_filter: Optional function that takes KernelMetadata and returns True for kernels to include
        :type metadata_filter: Callable[[KernelMetadata], bool]
        :param epilogue_args: Optional arguments to pass to kernel epilogue
        :type epilogue_args: EpilogueArguments | None
        :param cc: Optional compute capability to target; e.g., 90 for H100
        :type cc: int | None

        :return: list of all supported kernel configurations
        :rtype: list[Kernel]
        """
        raise NotImplementedError

    def _supports(self, args: RuntimeArguments) -> Status:
        """
        Classes may override this method to perform any additional checks that are not captured in metadata.
        Ideally, all/most checks should be captured in the metadata.
        By default, no such checks are performed and the method trivially returns Status.success().

        :param args: Arguments to check support for
        :type args: RuntimeArguments

        :return: Status indicating success, or reason why the kernel does not support the provided arguments
        :rtype: Status
        """
        return Status.success()

    @abstractmethod
    def _run(
        self,
        args: RuntimeArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        """
        A miniminal version of the run() method that assumes args are supported, a valid compiled artifact and a valid stream are provided.
        It is intended to be overridden by subclasses to implement the actual kernel execution, and be a minimal wrapper to launching the kernel.

        :param args: Arguments to run the kernel with. It is assumed that kernel.supports(args) is True.
        :type args: RuntimeArguments
        :param compiled_artifact: Compiled kernel object returned from the compile() method
        :type compiled_artifact: CompiledArtifact
        :param stream: Stream to execute the kernel on.
        :type stream: cuda.CUstream, torch.cuda.Stream, or other stream-like object
        :param workspace: Allocation of workspace at least as large as the workspace size returned from the get_workspace_size() method.
                          If the kernel does not require workspace, this can be None.
                          If a workspace of inappropriate size is provided, the behavior is undefined and the kernel may crash.
        :type workspace: any
        """
        raise NotImplementedError
