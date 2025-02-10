/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#include "pvc_flash_attn_ruuner.hpp"

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

  if (options.head_size == 64) {

    using TiledMma = TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _1, _1>, Stride<_1, _1, _1>>,
                              // Atom, Hardware(NUMBER OF CONCURRENT MMA), Iteration
                              Tile<Layout<Shape<_8, _8, _2>, Stride<_1, _16, _8>>,   // Vec Iteration, Hardware Jump,
                                                                                     // Iteration Jump for both M and N
                                   Layout<Shape<_16, _1, _4>, Stride<_1, _64, _16>>, // Vec Iteration, Hardware Jump,
                                                                                     // Iteration Jump for both M and N
                                   _64>>;                                            // K is going to be 64
    return options.is_causal ? FMHAConfig<true, Shape<_128, _64, _64>, TiledMma>::run(options)
                             : FMHAConfig<false, Shape<_128, _64, _64>, TiledMma>::run(options);
  } else if (options.head_size == 128) {
    using TiledMma = TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<Shape<_8, _2, _1>, Stride<_2, _1, _1>>,
                              // Atom, Hardware(NUMBER OF CONCURRENT MMA), Iteration
                              Tile<Layout<Shape<_8, _8, _2>, Stride<_1, _16, _8>>,   // Vec Iteration, Hardware Jump,
                                                                                     // Iteration Jump for both M and N
                                   Layout<Shape<_16, _2, _4>, Stride<_1, _64, _16>>, // Vec Iteration, Hardware Jump,
                                                                                     // Iteration Jump for both M and N
                                   _64>>;                                            // K

    return options.is_causal ? FMHAConfig<true, Shape<_128, _128, _64>, TiledMma>::run(options)
                             : FMHAConfig<false, Shape<_128, _128, _64>, TiledMma>::run(options);
  } else {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }
}
