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

"""A shim kernel on top of ``DenseGemmEFC`` that accepts torch-ordered user inputs.

The operator API supplies tensors in batch-first ``(L, M, N)`` order (and may
omit the ``L`` batch mode entirely for 2D inputs), whereas the EFC example's
``DenseGemmEFC`` consumes batch-last ``(M, N, L)`` tensors.  This thin subclass
prepends exactly that conversion -- add a unit batch mode, then permute A/B and
the supplemental epilogue tensors into batch-last order, leaving broadcast
remap sources untouched -- and then delegates to the verbatim example kernel.

Keeping the conversion isolated here lets ``evt/efc/`` stay a near-verbatim copy
of the EFC example, so the two can be re-synchronized with a plain diff.
"""

import cutlass
import cutlass.cute as cute

from cutlass.operators.providers.cutedsl.evt.efc.dense_gemm.sm100 import DenseGemmEFC


class PersistentDenseGemmEFCKernel(DenseGemmEFC):
    """Shim kernel to use :class:`DenseGemmEFC` with batch-first inputs."""

    @cute.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream,
        *supplemental_parameters,
    ):
        """Convert operator-API batch-first tensors, then run the example kernel."""

        def add_batch_mode(tensor: cute.Tensor) -> cute.Tensor:
            # Prepend a unit batch mode so 2D ``(M, K)`` inputs become ``(1, M, K)``.
            return cute.make_tensor(
                tensor.iterator,
                cute.prepend(tensor.layout, cute.make_layout(1), up_to_rank=3),
            )

        a = add_batch_mode(a)
        b = add_batch_mode(b)
        # Permute tensor modes from torch batch-first to CuTe batch-last.
        a = cute.make_tensor(
            a.iterator, cute.select(a.layout, [1, 2, 0])
        )  # (L,M,K)->(M,K,L)
        b = cute.make_tensor(
            b.iterator, cute.select(b.layout, [2, 1, 0])
        )  # (L,K,N)->(N,K,L)

        # Broadcast remap sources are passed through untouched -- ``remap_modes``
        # inside the kernel does their layout work (expansion, reordering).
        remap_sources = {
            attrs.mapped_source
            for attrs in self.efc.parameter_attributes.values()
            if attrs.mapped_source
        }
        param_names = self.efc.epilogue_parameter_names
        supplemental_parameters = tuple(
            t
            if name in remap_sources
            # Regular tensor: (L, M, N) -> rank 3 -> (M, N, L).
            else cute.make_tensor(
                add_batch_mode(t).iterator,
                cute.select(add_batch_mode(t).layout, [1, 2, 0]),
            )
            if isinstance(t, cute.Tensor)
            # Scalar: pass through.
            else t
            for name, t in zip(param_names, supplemental_parameters)
        )

        super().__call__(a, b, max_active_clusters, stream, *supplemental_parameters)
