/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
/*! \file
    \brief Flash Attention V2 Prefill for Intel PVC

    This example constructs and executes a Flash Attention Prefill kernel on Intel PVC. The
    definition of the GEMM, options etc for this example are defined in the associated
    pvc_flash_attn_runner.hpp header file.

    See https://arxiv.org/pdf/2307.08691 for details of Flash Attention V2 algorithm

    To run this example:
      $ ./examples/sycl/06_pvc_flash_attention/06_pvc_prefill_attention --seq_len_qo=512
        --seq_len_kv=512 --head_size_vo=128 --head_size_qk=128

    Causal masking of the first matrix multiplication is supported (`--is_causal`)

    To build & run this example (from your build dir):

      $ ninja 06_pvc_prefill_attention
      $ ./examples/sycl/06_pvc_flash_attention/06_pvc_prefill_attention

    Call with `--help` for information about available options
*/

#include "pvc_flash_attn_prefill_runner.hpp"

int main(int argc, const char **argv) {
  //
  // Parse options
  //

  Options options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  // Define the work-group tile shape depending on the head-size of the second matmul
  if (options.head_size_vo == 64 || options.head_size_vo == 96) {

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
                                      Layout<Shape<_128, _64, _64>>,
                                      Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;

    // Define whether or not to apply causal masking to the first matmul
    return options.is_causal ? FMHAConfig<true, Shape<_128, _64, _64, _64>, TiledMma>::run(options)
                             : FMHAConfig<false, Shape<_128, _64, _64, _64>, TiledMma>::run(options);
  } else if (options.head_size_vo == 192) {

    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
                                      Layout<Shape<_256, _64, _64>>,
                                      Layout<Shape<_16, _1, _1>, Stride<_1, _1, _1>>>::TiledMMA;

    return options.is_causal ? FMHAConfig<true, Shape<_256, _64, _64, _64>, TiledMma>::run(options)
                             : FMHAConfig<false, Shape<_256, _64, _64, _64>, TiledMma>::run(options);
  } else if (options.head_size_vo == 128) {
    using TiledMma =
        typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
                                      Layout<Shape<_128, _128, _64>>,
                                      Layout<Shape<_8, _2, _1>, Stride<_2, _1, _1>>>::TiledMMA;

    return options.is_causal ? FMHAConfig<true, Shape<_128, _128, _64, _64>, TiledMma>::run(options)
                             : FMHAConfig<false, Shape<_128, _128, _64, _64>, TiledMma>::run(options);
  } else {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }
}
