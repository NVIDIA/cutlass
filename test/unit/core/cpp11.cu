/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*
  Note:  CUTLASS 3x increases the host compiler requirements to C++17. However, certain
         existing integrations of CUTLASS require C++11 host compilers.

         Until this requirement can be lifted, certain headers with this annotation are required
         to be remain consistent with C++11 syntax.

         C++11 compatibility is enforced by this unit test: `cutlass_test_unit_core_cpp11`.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////

#include <cutlass/cutlass.h>

#include <cutlass/coord.h>
#include <cutlass/core_io.h>
#include <cutlass/array.h>
#include <cutlass/bfloat16.h>
#include <cutlass/fast_math.h>
#include <cutlass/float8.h>
#include <cutlass/half.h>
#include <cutlass/integer_subbyte.h>
#include <cutlass/kernel_hardware_info.h>
#include <cutlass/numeric_size.h>
#include <cutlass/numeric_types.h>
#include <cutlass/tfloat32.h>
#include <cutlass/workspace.h>
#include <cutlass/subbyte_reference.h>

#include <cutlass/conv/convolution.h>
#include <cutlass/conv/conv2d_problem_size.h>

#include <cutlass/epilogue/threadblock/predicated_tile_iterator_params.h>

#include <cutlass/gemm/gemm_enumerated_types.h>
#include <cutlass/gemm/kernel/tile_scheduler_params.h>
#include <cutlass/gemm/threadblock/threadblock_swizzle_streamk.h>

#include <cutlass/layout/matrix.h>
#include <cutlass/layout/pitch_linear.h>

#include <cutlass/transform/threadblock/predicated_tile_access_iterator_params.h>

/////////////////////////////////////////////////////////////////////////////////////////////////

#if (201700L <= __cplusplus )
#error "This file and all of its includes must be compilable as C++11."
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

int main() {
  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
