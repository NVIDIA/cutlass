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

#include "bmg_flash_attn_decode_runner.hpp"

template <int KVTile, int NumSG, bool PagedKV, bool Varlen>
int run_decode(Options const& options) {

#if !defined(HEAD_DIM)
  std::cerr << "HEAD_DIM must be defined" << std::endl;
  return -1;
#endif
  if (options.head_size_vo != HEAD_DIM) {
    std::cerr << "head_size_vo must be " << HEAD_DIM << ", but got " << options.head_size_vo << std::endl;
    return -1;
  }

#if HEAD_DIM == 64
    using ShapeQK = Shape<_1, Int<KVTile>, _64>;
    using ShapePV = Shape<_1, _32, Int<KVTile>>;
    using ShapeOutput = Shape<_1, _64, Int<KVTile>>;
    using SubgroupLayout = Layout<Shape<Int<NumSG>, _1, _1>, Stride<_1, _1, _1>>;

#elif HEAD_DIM == 96
    using ShapeQK = Shape<_1, Int<KVTile>, _64>;
    using ShapePV = Shape<_1, _32, Int<KVTile>>;
    using ShapeOutput = Shape<_1, _96, Int<KVTile>>;
    using SubgroupLayout = Layout<Shape<Int<NumSG>, _1, _1>, Stride<_1, _1, _1>>;

#elif HEAD_DIM == 128
    using ShapeQK = Shape<_1, Int<KVTile>, _64>;
    using ShapePV = Shape<_1, _32, Int<KVTile>>;
    using ShapeOutput = Shape<_1, _128, Int<KVTile>>;
    using SubgroupLayout = Layout<Shape<Int<NumSG>, _1, _1>, Stride<_1, _1, _1>>;

#elif HEAD_DIM == 192
    using ShapeQK = Shape<_1, Int<KVTile>, _64>;
    using ShapePV = Shape<_1, _32, Int<KVTile>>;
    using ShapeOutput = Shape<_1, _192, Int<KVTile>>;
    using SubgroupLayout = Layout<Shape<Int<NumSG>, _1, _1>, Stride<_1, _1, _1>>;

#endif

    return options.is_causal ? FMHAConfig<true, PagedKV, ShapeQK, ShapePV, ShapeOutput, SubgroupLayout, Varlen>::run(options)
                             : FMHAConfig<false, PagedKV, ShapeQK, ShapePV, ShapeOutput, SubgroupLayout, Varlen>::run(options);
}

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

  if(options.varlen && !options.use_paged_kv) {
    return run_decode<512, 8, false, true>(options);
  } else if(options.varlen && options.use_paged_kv) {
    return run_decode<512, 8, true, true>(options);
  } else if(!options.varlen && !options.use_paged_kv) {
    return run_decode<512, 8, false, false>(options);
  } else if(!options.varlen && options.use_paged_kv) {
    return run_decode<512, 8, true, false>(options);
  }
}
