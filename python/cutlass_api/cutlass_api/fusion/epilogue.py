
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


"""
Epilogue Visitor interface for compiling, and running visitor-based epilogue.
"""

import cutlass_api.fusion.backend
from cutlass_api.fusion.passes.util import cc_map


class EpilogueFunctorVisitor:
    """
    Apply an epilogue functor described by the epilogue EVT

    :param cc: compute capability
    :param visitor_frontend: user-provide visitor frontend

    """

    def __init__(self, cc: int, visitor, element_compute) -> None:
        # Type of Emitter based on CC
        self.emit_cls = getattr(
            cutlass_api.fusion.backend, f"Sm{cc_map[cc]}Emitter"
        )

        # Visitor Types
        self.visitor = visitor
        self.graph = visitor.dag_ir

        # Data types
        self.element_epilogue = element_compute  # element compute
        self.element_output = self.graph.get_node_meta("D").underlying_impl.element

        # Epilogue Thread Type
        if cc_map[cc] in [90, 100]:
            self.arg_c_type = self.visitor.arg_c_type
            self.arg_d_type = self.visitor.arg_d_type

        # Epilogue stages specialized for sm80 kernel
        if cc == 80:
            if hasattr(self.visitor, "epilogue_stages"):
                self.epilogue_stages = self.visitor.epilogue_stages
                assert self.epilogue_stages <= 2, (
                    "Only supports Stages <=2 in SM80 Epilogue"
                )

    def emit(self, operation):
        """
        Emit the C++ code
        """
        emitter = self.emit_cls(operation, self.graph)
        return emitter.emit()

    def get_smem_size(self, tile_description):
        """
        Get the shared memory size in bytes
        """
        return self.visitor.get_smem_size(tile_description)
