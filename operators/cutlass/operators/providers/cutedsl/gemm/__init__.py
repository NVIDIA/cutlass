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

# Importing is done for the side effect of registering the Operator classes with the provider.
# F401: Suppress linter warnings about unused import.
# I001: suppress linter warnings about import order, so we control Operator registration order
# E402: False warning about module-level imports not at top of file
# ruff: noqa: F401, I001, E402

import cutlass.operators.providers.cutedsl.gemm.sm100_persistent
import cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc
import cutlass.operators.providers.cutedsl.gemm.sm100_tgv_gemm
import cutlass.operators.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent
import cutlass.operators.providers.cutedsl.gemm.sm100_contiguous_offset_2d3d_dense_gemm
import cutlass.operators.providers.cutedsl.gemm.sm100_mixed_input
import cutlass.operators.providers.cutedsl.gemm.sm100_persistent_preferred_cluster
import cutlass.operators.providers.cutedsl.gemm.sm90_static_persistent
import cutlass.operators.providers.cutedsl.gemm.sm80_tensorop_gemm
