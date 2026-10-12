/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Example implementation of low latency GQA for the NVIDIA Blackwell SM100/SM103
  architecture using CUTLASS 3.

  Input tensor shapes:
    K has shape (kvL, dH, kvH, BS)
    Q has shape ((qHLocal, qL), dH, kvH, BS)
    V has shape (dH, kvL, kvH, BS)
    O has shape (dH, (qHLocal, qL), kvH, BS)
    kvL is max_seq_len, seq_lens[BS] is the actual seq len for each batch
    sinks has shape (qHLocal * kvH), i.e. one sink per q head

  --mode 1 enables the paged variant:
    Combined KV cache shape (num_pages_total, 2, Page_Size, kvH, dH), with BS folded into num_pages_total
      and KV(_,0,_,_,_) = K, KV(_,1,_,_,_) = V.
    page_table shape (kvL/Page_Size, BS), entry [p, bs] = physical page id of batch bs's per-batch page p.

  Example usage:
    $ ./examples/93_blackwell_low_latency_gqa --kvL 8192 --kvH 8 --qH 64 --BS 1
    $ ./examples/93_blackwell_low_latency_gqa --kvL 8192 --kvH 8 --qH 64 --BS 1 --mode 1
*/

// Standard library includes
#include <cassert>
#include <vector>
#include <memory>
#include <cmath>
#include <iostream>
#include <ctime>
#include <numeric>
#include <utility>
#include <getopt.h>

#include <cuda_runtime.h>
#include <cuda_profiler_api.h>

// Use Thrust to handle host/device allocations
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

// Cutlass includes
#include <cutlass/numeric_types.h>
#include <cutlass/util/print_error.hpp>
#include <cutlass/numeric_conversion.h>

// CuTe includes
#include <cute/tensor.hpp>                      // CuTe tensor implementation

#include "common.cuh"
#include "tgv_gqa.cuh"
#include "tgv_gqa_paged.cuh"

using namespace cute;

// K (kvL, dH, kvH, BS)
// Q ((qHLocal, qL), dH, kvH, BS)
// V (dH, kvL, kvH, BS)
// O (dH, (qHLocal, qL), kvH, BS)
// seq_lens (BS)
// Sinks ((qHLocal, qL), kvH)
template <
  class TypeAcc,
  int CTA_kvL,
  bool NoSink,
  class TensorQ, 
  class TensorK, 
  class TensorV, 
  class TensorO,
  class TensorSinks>
void
reference_gqa(
  TensorK const& tensor_K,
  TensorQ const& tensor_Q,
  TensorV const& tensor_V,
  TensorO const& tensor_O,
  int* seq_lens,
  TensorSinks const& tensor_Sinks,
  float softmax_scale,
  int sliding_window_size) {

  using TypeQKV = typename TensorQ::element_type;
  using TypeO = typename TensorO::element_type;

  using namespace cute;
  int kvL = size<0>(tensor_K);
  int dH = size<1>(tensor_K);
  int kvH = size<2>(tensor_K);
  int BS = size<3>(tensor_K);
  int qHLocal = size<0>(shape<0>(tensor_Q));
  int qL = size<1>(shape<0>(tensor_Q));

  // reference code don't handle oob either
  //assert(kvL % CTA_kvL == 0);
  int MaxKVBlocks = cutlass::ceil_div(kvL, CTA_kvL);

  // allocate intermediate tensors
  thrust::host_vector<TypeAcc> host_Acc1(kvL * qHLocal * qL * kvH * BS);
  auto tensor_Acc1 = make_tensor(host_Acc1.data(), make_layout(make_shape(kvL, make_shape(qHLocal, qL), kvH, BS))); // (kvL, (qHLocal, qL), kvH, BS)

  // CTA level fmax and fsum
  thrust::host_vector<TypeAcc> host_Fmax(MaxKVBlocks * qHLocal * qL * kvH * BS);
  Tensor tensor_Fmax = make_tensor(host_Fmax.data(), make_layout(make_shape(MaxKVBlocks, make_shape(qHLocal, qL), kvH, BS))); // (MaxKVBlocks, (qHLocal, qL), kvH, BS)
  fill(tensor_Fmax, -cutlass::platform::numeric_limits<TypeAcc>::infinity());

  thrust::host_vector<TypeAcc> host_Fsum(MaxKVBlocks * qHLocal * qL * kvH * BS);
  Tensor tensor_Fsum = make_tensor(host_Fsum.data(), make_layout(make_shape(MaxKVBlocks, make_shape(qHLocal, qL), kvH, BS))); // (MaxKVBlocks, (qHLocal, qL), kvH, BS)
  clear(tensor_Fsum);

  thrust::host_vector<TypeAcc> host_P(CTA_kvL * MaxKVBlocks * qHLocal * qL * kvH * BS);
  Tensor tensor_P = make_tensor(host_P.data(), make_layout(make_shape(make_shape(CTA_kvL, MaxKVBlocks), make_shape(qHLocal, qL), kvH, BS))); // ((CTA_kvL, MaxKVBlocks), (qHLocal, qL), kvH, BS)

  thrust::host_vector<TypeQKV> host_P_converted(CTA_kvL * MaxKVBlocks * qHLocal * qL * kvH * BS);
  Tensor tensor_P_converted = make_tensor(host_P_converted.data(), make_layout(make_shape(make_shape(CTA_kvL, MaxKVBlocks), make_shape(qHLocal, qL), kvH, BS))); // ((CTA_kvL, MaxKVBlocks), (qHLocal, qL), kvH, BS)

  thrust::host_vector<TypeAcc> host_Acc2(dH * qHLocal * qL * kvH * MaxKVBlocks * BS);
  auto tensor_Acc2 = make_tensor(host_Acc2.data(), make_layout(make_shape(dH, make_shape(qHLocal, qL), kvH, BS, MaxKVBlocks))); // (dH, (qHLocal, qL), kvH, BS, MaxKVBlocks)

  // cluster level fmax and fsum
  thrust::host_vector<TypeAcc> host_Fmax_cluster(qHLocal * qL * kvH * BS);
  Tensor tensor_Fmax_cluster = make_tensor(host_Fmax_cluster.data(), make_layout(make_shape(make_shape(qHLocal, qL), kvH, BS))); // ((qHLocal, qL), kvH, BS)

  thrust::host_vector<TypeAcc> host_Beta(qHLocal * qL * kvH * MaxKVBlocks * BS);
  Tensor tensor_Beta = make_tensor(host_Beta.data(), make_layout(make_shape(make_shape(qHLocal, qL), kvH, BS, MaxKVBlocks))); // ((qHLocal, qL), kvH, BS, MaxKVBlocks)

  thrust::host_vector<TypeAcc> host_Fsum_cluster(qHLocal * qL * kvH * BS);
  Tensor tensor_Fsum_cluster = make_tensor(host_Fsum_cluster.data(), make_layout(make_shape(make_shape(qHLocal, qL), kvH, BS))); // ((qHLocal, qL), kvH, BS)

  float softmax_scale_log2 = softmax_scale * static_cast<float>(M_LOG2E);

  for (int _BS = 0; _BS < BS; ++_BS) {
    int seq_len = seq_lens[_BS];
    int NumKVBlocks = cutlass::ceil_div(seq_len, CTA_kvL);
    int kvL_start = (sliding_window_size == 0) ? 0 : std::max(0, seq_len - sliding_window_size);
    int kvBlock_start = kvL_start / CTA_kvL;

    // bmm1 s = q * k * softmax_scale_log2
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
        for (int _qL = 0; _qL < qL; ++_qL) {
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            int start = _kvBlock * CTA_kvL;
            int end = std::min(start + CTA_kvL, seq_len);
            assert(start < end);
            for (int _kvL = start; _kvL < end; ++_kvL) {
              TypeAcc acc = TypeAcc(0.f);
              for (int _dH = 0; _dH < dH; ++_dH) {
                acc += tensor_K(_kvL, _dH, _kvH, _BS) * tensor_Q(make_coord(_qHLocal, _qL), _dH, _kvH, _BS);
              }
              tensor_Acc1(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS) =  (_kvL < kvL_start) ? -INFINITY : (acc * softmax_scale_log2);
            }
          }
        }
      }
    }

    // calculate m_ij
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
        for (int _qL = 0; _qL < qL; ++_qL) {
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            int start = _kvBlock * CTA_kvL;
            int end = std::min(start + CTA_kvL, seq_len);
            assert(start < end);
            TypeAcc& fmax = tensor_Fmax(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS);
            fmax = tensor_Acc1(start, make_coord(_qHLocal, _qL), _kvH, _BS);
            for (int _kvL = start + 1; _kvL < end; ++_kvL) {
              fmax = std::max(fmax, tensor_Acc1(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS));
            }
          }
        }
      }
    }

    // calculate p = exp2f(s - m_ij)
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
        for (int _qL = 0; _qL < qL; ++_qL) {
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            int start = _kvBlock * CTA_kvL;
            int end = std::min(start + CTA_kvL, seq_len);
            assert(start < end);
            for (int _kvL = start; _kvL < end; ++_kvL) {
              tensor_P(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS) = std::exp2f(tensor_Acc1(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS) - tensor_Fmax(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS));
            }
          }
        }
      }
    }

    // calculate l_ij = sum(p)
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
        for (int _qL = 0; _qL < qL; ++_qL) {
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            int start = _kvBlock * CTA_kvL;
            int end = std::min(start + CTA_kvL, seq_len);
            assert(start < end);
            TypeAcc sum = TypeAcc(0.f);
            for (int _kvL = start; _kvL < end; ++_kvL) {
              sum += tensor_P(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS);
            }
            tensor_Fsum(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS) = sum;
          }
        }
      }
    }

    // convert P from fp32 to bf16/fp8
    cutlass::NumericConverter<TypeQKV, TypeAcc> converter_p;
    for (int i = 0; i < tensor_P(_,_,_,_BS).size(); i++) {
      tensor_P_converted(_,_,_,_BS)[i] = converter_p(tensor_P(_,_,_,_BS)[i]);
    }

    // bmm2 acc2 = v * p
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _dH = 0; _dH < dH; ++_dH) {
        for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
          for (int _qL = 0; _qL < qL; ++_qL) {
            for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
              int start = _kvBlock * CTA_kvL;
              int end = std::min(start + CTA_kvL, seq_len);
              assert(start < end);
              TypeAcc acc = TypeAcc(0.f);
              for (int _kvL = start; _kvL < end; ++_kvL) {
                acc += tensor_V(_dH, _kvL, _kvH, _BS) * tensor_P_converted(_kvL, make_coord(_qHLocal, _qL), _kvH, _BS);
              }
              tensor_Acc2(_dH, make_coord(_qHLocal, _qL), _kvH, _BS, _kvBlock) = acc;
            }
          }
        }
      }
    }

    // calculate cluster level fmax and fsum
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
        for (int _qL = 0; _qL < qL; ++_qL) {
          TypeAcc& fmax = tensor_Fmax_cluster(make_coord(_qHLocal, _qL), _kvH, _BS);
          fmax = tensor_Fmax(kvBlock_start, make_coord(_qHLocal, _qL), _kvH, _BS);
          for (int _kvBlock = kvBlock_start + 1; _kvBlock < NumKVBlocks; ++_kvBlock) {
            fmax = std::max(fmax, tensor_Fmax(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS));
          }

          // calculate beta
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            tensor_Beta(make_coord(_qHLocal, _qL), _kvH, _BS, _kvBlock) = std::exp2f(tensor_Fmax(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS) - fmax);
          }

          // calculate fsum
          TypeAcc sum = TypeAcc(0.f);
          for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
            sum += tensor_Fsum(_kvBlock, make_coord(_qHLocal, _qL), _kvH, _BS) * tensor_Beta(make_coord(_qHLocal, _qL), _kvH, _BS, _kvBlock);
          }
          tensor_Fsum_cluster(make_coord(_qHLocal, _qL), _kvH, _BS) = sum;
          if constexpr (!NoSink) {
            tensor_Fsum_cluster(make_coord(_qHLocal, _qL), _kvH, _BS) += std::exp2f(tensor_Sinks(make_coord(_qHLocal, _qL), _kvH) * (float)M_LOG2E - fmax);
          }
        }
      }
    }

    // convert O from fp32 to bf16/fp8
    cutlass::NumericConverter<TypeO, TypeAcc> converter_o;
    // final reduction
    for (int _kvH = 0; _kvH < kvH; ++_kvH) {
      for (int _dH = 0; _dH < dH; ++_dH) {
        for (int _qHLocal = 0; _qHLocal < qHLocal; ++_qHLocal) {
          for (int _qL = 0; _qL < qL; ++_qL) {
            TypeAcc acc = TypeAcc(0.f);
            for (int _kvBlock = kvBlock_start; _kvBlock < NumKVBlocks; ++_kvBlock) {
              acc += tensor_Acc2(_dH, make_coord(_qHLocal, _qL), _kvH, _BS, _kvBlock) * tensor_Beta(make_coord(_qHLocal, _qL), _kvH, _BS, _kvBlock);
            }
            tensor_O(_dH, make_coord(_qHLocal, _qL), _kvH, _BS) = converter_o(acc / tensor_Fsum_cluster(make_coord(_qHLocal, _qL), _kvH, _BS));
          }
        }
      }
    }
  }

  /*int example_row = 0;
  int example_kvH = 0;
  int example_kvBlock = 0;
  int example_BS = 3;
  print("tensor_Acc1:\t"); print(tensor_Acc1(_, _, example_kvH, example_BS)); print("\n");
  print("tensor_Fmax:\t"); print_tensor(tensor_Fmax(example_kvBlock,_,example_kvH,example_BS)); print("\n");
  print("tensor_P:\t"); print_tensor(tensor_P(make_coord(example_row, example_kvBlock),_,example_kvH,example_BS)); print("\n");
  print("tensor_Fsum:\t"); print_tensor(tensor_Fsum(example_kvBlock,_,example_kvH,example_BS)); print("\n");
  print("tensor_P_converted:\t"); print_tensor(tensor_P_converted(make_coord(example_row, example_kvBlock),_,example_kvH,example_BS)); print("\n");
  print("tensor_Acc2:\t"); print_tensor(tensor_Acc2(example_row,_,example_kvH,example_BS,example_kvBlock)); print("\n");
  print("tensor_Fmax_cluster:\t"); print_tensor(tensor_Fmax_cluster(_,example_kvH,example_BS)); print("\n");
  print("tensor_Beta:\t"); print_tensor(tensor_Beta(_,example_kvH,example_BS,_)); print("\n");
  print("tensor_Fsum_cluster:\t"); print_tensor(tensor_Fsum_cluster(_,example_kvH,example_BS)); print("\n");
  print("tensor_O:\t"); print_tensor(tensor_O(example_row,_,example_kvH,example_BS)); print("\n");*/
}

template <class Tensor>
void
initialize_tensor(Tensor& tensor, cute::tuple<int, int> value_range = {-4, 4}) {
  using DataType = typename Tensor::element_type;
  auto [min, max] = value_range;
  for (int i = 0; i < cute::size(tensor); i++) {
    tensor(i) = DataType(int((max-min)*(rand() / double(RAND_MAX)) + min));
  }
}

// Compares two CuTe tensors with torch.allclose semantics
// Returns true if: |input_i - other_i| <= atol + rtol x |other_i| for all elements
template <class TensorInput, class TensorOther>
bool
cute_allclose(
  TensorInput const& input,
  TensorOther const& other,
  float rtol = 1e-05f,
  float atol = 1e-08f,
  bool equal_nan = false) {
  using namespace cute;

  // Tensors must have the same size
  if (size(input) != size(other)) {
    std::cerr << "Error: Tensor sizes don't match. input size: " << size(input) 
              << ", other size: " << size(other) << std::endl;
    return false;
  }

  int mismatches = 0;
  const int max_print = 10; // Only print first 10 mismatches

  for (int i = 0; i < size(input); ++i) {
    float input_val = float(input(i));
    float other_val = float(other(i));

    // Handle NaN comparison
    bool input_is_nan = std::isnan(input_val);
    bool other_is_nan = std::isnan(other_val);

    if (input_is_nan || other_is_nan) {
      if (equal_nan && input_is_nan && other_is_nan) {
        continue; // Both NaN and equal_nan is true
      } 
      else if (input_is_nan || other_is_nan) {
        if (mismatches < max_print) {
          std::cerr << "Mismatch at index " << i << ": input=" << input_val 
                    << ", other=" << other_val << " (NaN detected)" << std::endl;
        }
        mismatches++;
        continue;
      }
    }

    // Check torch.allclose condition: |input - other| <= atol + rtol * |other|
    float diff = std::abs(input_val - other_val);
    float threshold = atol + rtol * std::abs(other_val);

    if (diff > threshold) {
      if (mismatches < max_print) {
        std::cerr << "Mismatch at index " << i << ": input=" << input_val 
                  << ", other=" << other_val << ", diff=" << diff 
                  << ", threshold=" << threshold << std::endl;
      }
      mismatches++;
    }
  }

  if (mismatches > 0) {
    std::cerr << "Total mismatches: " << mismatches << " out of " << size(input) << " elements" << std::endl;
    return false;
  }

  return true;
}

struct ProblemStride {
  int stride_Q_kvH;
  int stride_Q_qHLocal;
  int stride_Q_qL;
  int stride_Q_dH;
  int stride_Q_BS;

  int stride_K_kvH;
  int stride_K_kvL;
  int stride_K_dH;
  int stride_K_BS;

  int stride_V_kvH;
  int stride_V_kvL;
  int stride_V_dH;
  int stride_V_BS;

  int stride_O_kvH;
  int stride_O_qHLocal;
  int stride_O_qL;
  int stride_O_dH;
  int stride_O_BS;

  // Combined KV (paged mode) layout: (num_pages_total, 2, Page_Size, kvH, dH).
  // BS is folded into num_pages_total = BS * kvL / Page_Size (no explicit BS mode).
  // Mode 1 is the K/V selector; harness picks dH-innermost packed strides below.
  int stride_KV_pages;
  int stride_KV_KV;
  int stride_KV_ps;
  int stride_KV_kvH;
  int stride_KV_dH;

  // Page table (paged mode) layout: (kvL/Page_Size, BS), entry [p, bs] = physical page id of batch bs's per-batch
  // page p. Mode 0 is innermost in memory (per-batch page id, stride 1); mode 1 advances by pages_per_batch across batches.
  int stride_PT_p;
  int stride_PT_BS;
};

ProblemStride make_gqa_stride(int kvH, int qHLocal, int qL, int kvL, int dH, int BS, int Page_Size) {
  ProblemStride stride;

  // Q shape ((qHLocal, qL), dH, kvH, BS), where dH is contiguous
  // slowest moving dim->fastest moving dim: BS, qL, kvH, qHLocal, dH
  stride.stride_Q_kvH = qHLocal * dH;
  stride.stride_Q_qHLocal = dH;
  stride.stride_Q_qL = kvH * qHLocal * dH;
  stride.stride_Q_dH = 1;
  stride.stride_Q_BS = kvH * qHLocal * dH * qL;

  // K shape (kvL, dH, kvH, BS), where dH is contiguous
  // slowest moving dim->fastest moving dim: BS, kvL, kvH, dH
  stride.stride_K_kvH = dH;
  stride.stride_K_kvL = kvH * dH;
  stride.stride_K_dH = 1;
  stride.stride_K_BS = kvL * dH * kvH;

  // V shape (dH, kvL, kvH, BS), where dH is contiguous
  // slowest moving dim->fastest moving dim: BS, kvL, kvH, dH
  stride.stride_V_kvH = dH;
  stride.stride_V_kvL = kvH * dH;
  stride.stride_V_dH = 1;
  stride.stride_V_BS = kvL * dH * kvH;

  // O shape (dH, (qHLocal, qL), kvH, BS), where dH is contiguous
  // slowest moving dim->fastest moving dim: BS, qL, kvH, qHLocal, dH
  stride.stride_O_kvH = qHLocal * dH;
  stride.stride_O_qHLocal = dH;
  stride.stride_O_qL = kvH * qHLocal * dH;
  stride.stride_O_dH = 1;
  stride.stride_O_BS = kvH * qHLocal * dH * qL;

  // Combined KV (paged) shape (num_pages_total, 2, Page_Size, kvH, dH), dH innermost contiguous.
  // BS is folded into num_pages_total; the (bs_idx, per_batch_page_idx) -> physical page mapping lives in the
  // page_table tensor (see stride_PT_*). Strides slowest -> fastest:
  // num_pages_total, KV (K/V selector), Page_Size, kvH, dH.
  stride.stride_KV_dH = 1;
  stride.stride_KV_kvH = dH;
  stride.stride_KV_ps = kvH * dH;
  stride.stride_KV_KV = Page_Size * kvH * dH;
  stride.stride_KV_pages = 2 * Page_Size * kvH * dH;

  // Page table shape (kvL/Page_Size, BS); per-batch page idx is mode 0 (contiguous, stride 1), batch is mode 1 (advances by pages_per_batch).
  stride.stride_PT_p = 1;
  stride.stride_PT_BS = kvL / Page_Size;

  return stride;
}

class GQATester {
public:
  // Kernel config constants
  using TypeQKV = cutlass::bfloat16_t;
  using TypeO = cutlass::bfloat16_t;
  using TypeAcc = float;
  static constexpr int CTA_qHLocal = 8;
  static constexpr int CTA_qL = 1;
  static constexpr int CTA_kvL = 128;
  static constexpr int CTA_dH = 64;
  // Page_Size only used by gqa_paged (mode 1). Page_Size must divide CTA_kvL; CTA_kvL/Page_Size = pages per CTA tile.
  static constexpr int Page_Size = 32;
  static constexpr int BMM1_DMA_Stage = 3;
  static constexpr int BMM2_DMA_Stage = 3;
  // Page-idx staging (mode 1 only). Num_Page_Idx_Per_Stage must be a multiple of CTA_kvL/Page_Size
  // so a DMA stage's pages live in one pi stage. Page_Idx_Stage = pipeline depth on the page-idx side.
  static constexpr int Page_Idx_Stage = 2;
  static constexpr int Num_Page_Idx_Per_Stage = 8 * (CTA_kvL / Page_Size);
  static constexpr int MaxSplits = 8;
  static constexpr int NumReductionCTA = 8;
  static constexpr bool NoSink = true;
  static constexpr bool VarSeqLens = false;

private:
  int kvH_, qHLocal_, qL_, kvL_, dH_, BS_;
  float softmax_scale_;
  ProblemStride stride_;
  int sliding_window_size_;
  int mode_; // 0: gqa, 1: gqa_paged

  // Host vectors
  thrust::host_vector<TypeQKV> host_Q_;
  thrust::host_vector<TypeQKV> host_K_;
  thrust::host_vector<TypeQKV> host_V_;
  thrust::host_vector<TypeO> host_O_;
  thrust::host_vector<TypeO> host_reference_O_;
  thrust::host_vector<int> host_seq_lens_;
  thrust::host_vector<TypeAcc> host_sinks_;

  // Device vectors
  thrust::device_vector<TypeQKV> device_Q_;
  thrust::device_vector<TypeQKV> device_K_;
  thrust::device_vector<TypeQKV> device_V_;
  // Combined KV cache for paged mode (mode_ == 1).
  // Layout: (num_pages_total, 2, Page_Size, kvH, dH) with dH innermost; BS is folded into num_pages_total.
  // The (bs, per_batch_page_idx) -> physical page mapping is held in device_page_table_ (built by
  // build_random_page_table: a Fisher-Yates shuffle of [0, num_pages_total) sliced per batch).
  // KV(_,0,_,_,_) is K, KV(_,1,_,_,_) is V.
  thrust::device_vector<TypeQKV> device_KV_;
  // Page table for paged mode. Logical shape (kvL/Page_Size, BS); entry [p, bs] is the physical page id for
  // batch bs and per-batch page index p. Padded by Num_Page_Idx_Per_Stage ints at the tail so the device's
  // last-pi-stage cp.async never reads past the allocation.
  thrust::device_vector<int> device_page_table_;
  thrust::device_vector<TypeO> device_O_;
  thrust::device_vector<int> device_seq_lens_;
  thrust::device_vector<TypeAcc> device_sinks_;

  // Build the host-side page table: tail-padded buffer with shape (kvL/Page_Size, BS) and contents = a random
  // per-batch slice of a Fisher-Yates shuffle of [0, num_pages_total). Each batch's slice length is
  // seq_len[bs]/Page_Size, so total pages assigned = sum(seq_len_pages) <= num_pages_total. Tail padding
  // (Num_Page_Idx_Per_Stage ints) covers the device's last-pi-stage cp.async OOB read.
  thrust::host_vector<int> build_random_page_table(int pages_per_batch, int num_pages_total) {
    thrust::host_vector<int> host_page_table(num_pages_total + Num_Page_Idx_Per_Stage, 0);
    auto host_tensor_page_table = make_tensor(host_page_table.data(),
        make_layout(make_shape(pages_per_batch, BS_),
                    make_stride(stride_.stride_PT_p, stride_.stride_PT_BS)));
    std::vector<int> perm(num_pages_total);
    std::iota(perm.begin(), perm.end(), 0);
    for (int i = num_pages_total - 1; i > 0; --i) {
      std::swap(perm[i], perm[rand() % (i + 1)]);
    }
    int perm_offset = 0;
    for (int bs = 0; bs < BS_; ++bs) {
      // ceil_div: a partial tail page (seq_len % Page_Size != 0) still needs a physical page assigned
      // so the kernel's address-by-page lookup for positions [floor(seq_len/Page_Size)*Page_Size, seq_len)
      // hits real packed K/V data. Positions past seq_len are masked by the kernel and don't contribute.
      int seq_len_pages = cutlass::ceil_div(host_seq_lens_[bs], Page_Size);
      for (int p = 0; p < seq_len_pages; ++p) {
        host_tensor_page_table(p, bs) = perm[perm_offset + p];
      }
      perm_offset += seq_len_pages;
    }
    return host_page_table;
  }

  // Pack the flat per-batch K/V buffers into the combined paged KV layout, using the page table for the
  // (bs, per_batch_page) -> physical page mapping. Bounded by seq_len_pages per batch so out-of-seq-len entries
  // (which the page table doesn't populate) aren't dereferenced.
  template <class HostTensorPageTable, class HostTensorK, class HostTensorV, class HostTensorKV>
  void pack_combined_kv(HostTensorPageTable const& host_tensor_page_table,
                        HostTensorK const& host_tensor_K, HostTensorV const& host_tensor_V,
                        HostTensorKV& host_tensor_KV) {
    for (int bs = 0; bs < BS_; ++bs) {
      // ceil_div pages so the partial tail page (when seq_len isn't page-aligned) is packed.
      // We pack the full Page_Size for the tail page; positions past seq_len carry whatever
      // initialize_tensor wrote into the K/V buffers, but the kernel masks those out.
      int seq_len_pages = cutlass::ceil_div(host_seq_lens_[bs], Page_Size);
      for (int p = 0; p < seq_len_pages; ++p) {
        int global_page = host_tensor_page_table(p, bs);
        for (int ps = 0; ps < Page_Size; ++ps) {
          int kvl = p * Page_Size + ps;
          for (int kvh = 0; kvh < kvH_; ++kvh) {
            for (int dh = 0; dh < dH_; ++dh) {
              host_tensor_KV(global_page, 0, ps, kvh, dh) = host_tensor_K(kvl, dh, kvh, bs);
              host_tensor_KV(global_page, 1, ps, kvh, dh) = host_tensor_V(dh, kvl, kvh, bs);
            }
          }
        }
      }
    }
  }

public:
  GQATester(int kvH, int qH, int qL, int kvL, int dH, int BS, float softmax_scale, int sliding_window_size, int mode = 0) :
  kvH_(kvH), qHLocal_(qH / kvH), qL_(qL), kvL_(kvL), dH_(dH), BS_(BS), softmax_scale_(softmax_scale), sliding_window_size_(sliding_window_size), mode_(mode) {
    assert(sliding_window_size_ >= 0);
    // Allocate host memory
    host_Q_.resize(kvH_ * qHLocal_ * qL_ * dH_ * BS_);
    host_K_.resize(kvH_ * kvL_ * dH_ * BS_);
    host_V_.resize(kvH_ * kvL_ * dH_ * BS_);
    host_O_.resize(kvH_ * qHLocal_ * qL_ * dH_ * BS_);
    host_reference_O_.resize(kvH_ * qHLocal_ * qL_ * dH_ * BS_);
    host_seq_lens_.resize(BS_);
    host_sinks_.resize(qHLocal_ * kvH_); // one sink per q head

    stride_ = make_gqa_stride(kvH_, qHLocal_, qL_, kvL_, dH_, BS_, Page_Size);

    // Create host CuTe tensors for initialization
    auto host_tensor_Q = make_tensor(host_Q_.data(), TGV::gqa::make_layout_Q(kvH_, qHLocal_, qL_, dH_, BS_, stride_.stride_Q_kvH, stride_.stride_Q_qHLocal, stride_.stride_Q_qL, stride_.stride_Q_dH, stride_.stride_Q_BS));
    auto host_tensor_K = make_tensor(host_K_.data(), TGV::gqa::make_layout_K(kvH_, kvL_, dH_, BS_, stride_.stride_K_kvH, stride_.stride_K_kvL, stride_.stride_K_dH, stride_.stride_K_BS));
    auto host_tensor_V = make_tensor(host_V_.data(), TGV::gqa::make_layout_V(kvH_, kvL_, dH_, BS_, stride_.stride_V_kvH, stride_.stride_V_kvL, stride_.stride_V_dH, stride_.stride_V_BS));
    auto host_tensor_sinks = make_tensor(host_sinks_.data(), TGV::gqa::make_layout_sinks(qHLocal_, qL_, kvH_));

    // Initialize Q, K, V tensors with random values
    initialize_tensor(host_tensor_Q);
    initialize_tensor(host_tensor_K);
    initialize_tensor(host_tensor_V);
    for (int i = 0; i < BS_; ++i) {
      if (VarSeqLens) {
        host_seq_lens_[i] = rand() % kvL_ + 1;
      } 
      else { // all the batch have the same seq len
        host_seq_lens_[i] = kvL_;
      }
    }
    for (int i = 0; i < qHLocal_ * kvH_; ++i) {
      host_sinks_[i] = rand() / (float)RAND_MAX;
    }

    // Allocate device memory and copy H2D
    device_Q_ = host_Q_;
    device_K_ = host_K_;
    device_V_ = host_V_;
    device_O_.resize(kvH_ * qHLocal_ * qL_ * dH_ * BS_);
    device_seq_lens_ = host_seq_lens_;
    device_sinks_ = host_sinks_;

    // For paged mode, build the page_table and combined KV tensor on device. The harness owns the layouts:
    // stride_KV_* and stride_PT_* were computed in make_gqa_stride above and are used both here (host pack)
    // and downstream (passed into gqa_paged_host as stride args). Combined KV shape: (num_pages_total, 2,
    // Page_Size, kvH, dH), BS folded into num_pages_total. We populate the page_table via
    // build_random_page_table (Fisher-Yates shuffle of [0, num_pages_total) sliced per batch) to stress
    // non-contiguous mappings.
    if (mode_ == 1) {
      assert(kvL_ % Page_Size == 0);
      assert(kvL_ % CTA_kvL == 0);
      int pages_per_batch = kvL_ / Page_Size;
      int num_pages_total = BS_ * pages_per_batch;

      auto host_page_table = build_random_page_table(pages_per_batch, num_pages_total);
      auto host_tensor_page_table = make_tensor(host_page_table.data(),
          make_layout(make_shape(pages_per_batch, BS_),
                      make_stride(stride_.stride_PT_p, stride_.stride_PT_BS)));

      thrust::host_vector<TypeQKV> host_KV(num_pages_total * stride_.stride_KV_pages);
      auto host_tensor_KV = make_tensor(host_KV.data(),
          make_layout(make_shape(num_pages_total, 2, Page_Size, kvH_, dH_),
                      make_stride(stride_.stride_KV_pages, stride_.stride_KV_KV,
                                  stride_.stride_KV_ps, stride_.stride_KV_kvH, stride_.stride_KV_dH)));
      pack_combined_kv(host_tensor_page_table, host_tensor_K, host_tensor_V, host_tensor_KV);

      device_KV_ = host_KV;
      device_page_table_ = host_page_table;
    }

    gpuErrChk(cudaDeviceSynchronize());
  }

    void run_kernel(bool pdl, int pdl_count = -1, cudaStream_t stream = 0) {
      if (mode_ == 0) {
        TGV::gqa::gqa_host<
          TypeQKV, TypeO, TypeAcc,
          CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
          BMM1_DMA_Stage, BMM2_DMA_Stage,
          MaxSplits,
          NumReductionCTA>(
          device_K_.data().get(), device_Q_.data().get(), device_V_.data().get(), device_O_.data().get(),
          device_seq_lens_.data().get(),
          NoSink ? nullptr : device_sinks_.data().get(),
          kvH_, qHLocal_, qL_, kvL_, dH_, BS_,
          stride_.stride_K_kvH, stride_.stride_K_kvL, stride_.stride_K_dH, stride_.stride_K_BS,
          stride_.stride_Q_kvH, stride_.stride_Q_qHLocal, stride_.stride_Q_qL, stride_.stride_Q_dH, stride_.stride_Q_BS,
          stride_.stride_V_kvH, stride_.stride_V_kvL, stride_.stride_V_dH, stride_.stride_V_BS,
          stride_.stride_O_kvH, stride_.stride_O_qHLocal, stride_.stride_O_qL, stride_.stride_O_dH, stride_.stride_O_BS,
          softmax_scale_,
          sliding_window_size_,
          pdl, pdl_count, stream);
      }
      else {
        TGV::gqa_paged::gqa_paged_host<
          TypeQKV, TypeO, TypeAcc,
          CTA_qHLocal, CTA_qL, CTA_kvL, CTA_dH,
          Page_Size,
          BMM1_DMA_Stage, BMM2_DMA_Stage,
          Page_Idx_Stage, Num_Page_Idx_Per_Stage,
          MaxSplits,
          NumReductionCTA>(
          device_KV_.data().get(),
          device_Q_.data().get(),
          device_O_.data().get(),
          NoSink ? nullptr : device_sinks_.data().get(),
          device_seq_lens_.data().get(),
          device_page_table_.data().get(),
          kvH_, qHLocal_, qL_, kvL_, dH_, BS_,
          stride_.stride_KV_pages, stride_.stride_KV_KV, stride_.stride_KV_ps, stride_.stride_KV_kvH, stride_.stride_KV_dH,
          stride_.stride_Q_kvH, stride_.stride_Q_qHLocal, stride_.stride_Q_qL, stride_.stride_Q_dH, stride_.stride_Q_BS,
          stride_.stride_O_kvH, stride_.stride_O_qHLocal, stride_.stride_O_qL, stride_.stride_O_dH, stride_.stride_O_BS,
          stride_.stride_PT_p, stride_.stride_PT_BS,
          softmax_scale_,
          sliding_window_size_,
          pdl, pdl_count, stream);
      }
    }

    bool verify() {
      // Run the GPU kernel
      run_kernel(false);
      gpuErrChk(cudaDeviceSynchronize());

      // Copy D2H
      host_O_ = device_O_;

      // Create tensors for verification using helper methods
      auto host_tensor_Q = make_tensor(host_Q_.data(), TGV::gqa::make_layout_Q(kvH_, qHLocal_, qL_, dH_, BS_, stride_.stride_Q_kvH, stride_.stride_Q_qHLocal, stride_.stride_Q_qL, stride_.stride_Q_dH, stride_.stride_Q_BS));
      auto host_tensor_K = make_tensor(host_K_.data(), TGV::gqa::make_layout_K(kvH_, kvL_, dH_, BS_, stride_.stride_K_kvH, stride_.stride_K_kvL, stride_.stride_K_dH, stride_.stride_K_BS));
      auto host_tensor_V = make_tensor(host_V_.data(), TGV::gqa::make_layout_V(kvH_, kvL_, dH_, BS_, stride_.stride_V_kvH, stride_.stride_V_kvL, stride_.stride_V_dH, stride_.stride_V_BS));
      auto host_tensor_O = make_tensor(host_O_.data(), TGV::gqa::make_layout_O(kvH_, qHLocal_, qL_, dH_, BS_, stride_.stride_O_kvH, stride_.stride_O_qHLocal, stride_.stride_O_qL, stride_.stride_O_dH, stride_.stride_O_BS));
      auto host_reference_tensor_O = make_tensor(host_reference_O_.data(), TGV::gqa::make_layout_O(kvH_, qHLocal_, qL_, dH_, BS_, stride_.stride_O_kvH, stride_.stride_O_qHLocal, stride_.stride_O_qL, stride_.stride_O_dH, stride_.stride_O_BS));
      auto host_seq_lens_tensor = make_tensor(host_seq_lens_.data(), make_layout(make_shape(BS_)));
      auto host_tensor_sinks = make_tensor(host_sinks_.data(), TGV::gqa::make_layout_sinks(qHLocal_, qL_, kvH_));

      gpuErrChk(cudaDeviceSynchronize());

      print("host_seq_lens_tensor:\t"); print_tensor(host_seq_lens_tensor);
      print("host_tensor_Q:\t"); print(host_tensor_Q); print("\n");
      print("host_tensor_K:\t"); print(host_tensor_K); print("\n");
      print("host_tensor_V:\t"); print(host_tensor_V); print("\n");
      print("host_tensor_O:\t"); print(host_tensor_O); print("\n");
      print("host_reference_tensor_O:\t"); print(host_reference_tensor_O); print("\n");
      print("host_tensor_sinks:\t"); print(host_tensor_sinks); print("\n");

      // Execute reference GQA kernel
      reference_gqa<TypeAcc, CTA_kvL, NoSink>(
        host_tensor_K, host_tensor_Q, host_tensor_V, host_reference_tensor_O, host_seq_lens_.data(), host_tensor_sinks, softmax_scale_, sliding_window_size_);

      // Compare results using torch.allclose semantics
      // For bfloat16, use more relaxed tolerances due to reduced precision
      bool success = cute_allclose(host_tensor_O, host_reference_tensor_O, 
                                    1e-2f,  // rtol (relative tolerance) 
                                    1e-3f); // atol (absolute tolerance)
      //print("host_tensor_O:\t"); print_tensor(host_tensor_O(_,_,0)); print("\n");
      //print("host_reference_tensor_O:\t"); print_tensor(host_reference_tensor_O(_,_,0)); print("\n");

      std::cout << "Execution is " << ((success) ? "successful." : "failed.") << std::endl;

      return success;
    }

};

void benchmark_gqa(int kvH, int qH, int qL, int kvL, int dH, int BS, float softmax_scale, int sliding_window_size, int mode, bool pdl, int pdl_count, int num_testers = 4, int bench_iters = 100) {
  std::cout << "=== GQA Benchmark ===" << std::endl;
  std::cout << "Problem size: kvH=" << kvH << ", qH=" << qH << ", qL=" << qL << ", kvL=" << kvL << ", dH=" << dH << ", BS=" << BS << ", sliding_window_size=" << sliding_window_size << std::endl;
  std::cout << "Mode: " << mode << " (" << (mode == 0 ? "gqa" : "gqa_paged") << ")" << std::endl;
  std::cout << "Number of testers (L2 thrashing): " << num_testers << std::endl;
  std::cout << "Benchmark iterations: " << bench_iters << std::endl;

  // Create multiple tester instances to thrash L2 cache
  std::vector<std::unique_ptr<GQATester>> testers;
  for (int i = 0; i < num_testers; ++i) {
    testers.push_back(std::make_unique<GQATester>(kvH, qH, qL, kvL, dH, BS, softmax_scale, sliding_window_size, mode));
  }
  std::cout << "Created " << num_testers << " GQATester instances" << std::endl;

  // Create CUDA stream for graph capture
  cudaStream_t stream;
  gpuErrChk(cudaStreamCreate(&stream));

  // Capture CUDA graph
  std::cout << "Capturing CUDA graph..." << std::endl;
  cudaGraph_t graph;
  cudaGraphExec_t graph_exec;

  gpuErrChk(cudaStreamBeginCapture(stream, cudaStreamCaptureModeGlobal));
  // Capture round robin execution pattern
  for (int iter = 0; iter < bench_iters; ++iter) {
    int tester_idx = iter % num_testers;
    // Note: We need to run kernels on the same stream for graph capture
    // This requires modifying the kernel launch to accept a stream parameter
    // For now, we'll capture a simpler pattern and measure accordingly
    testers[tester_idx]->run_kernel(pdl, pdl_count, stream);
  }
  gpuErrChk(cudaStreamEndCapture(stream, &graph));
  gpuErrChk(cudaGraphInstantiate(&graph_exec, graph, NULL, NULL, 0));
  std::cout << "CUDA graph captured and instantiated" << std::endl;

  // Warmup: run kernels in round robin fashion
  std::cout << "Starting warmup..." << std::endl;
  gpuErrChk(cudaGraphLaunch(graph_exec, stream));
  gpuErrChk(cudaDeviceSynchronize());
  std::cout << "Warmup completed" << std::endl;

  // Benchmark: replay graph and measure time
  std::cout << "Starting benchmark..." << std::endl;

  // Create CUDA events for timing
  cudaEvent_t start_event, stop_event;
  gpuErrChk(cudaEventCreate(&start_event));
  gpuErrChk(cudaEventCreate(&stop_event));

  gpuErrChk(cudaProfilerStart());
  gpuErrChk(cudaEventRecord(start_event, stream));
  gpuErrChk(cudaGraphLaunch(graph_exec, stream));
  gpuErrChk(cudaEventRecord(stop_event, stream));
  gpuErrChk(cudaProfilerStop());

  gpuErrChk(cudaDeviceSynchronize());

  // Calculate timing
  float total_time_ms;
  gpuErrChk(cudaEventElapsedTime(&total_time_ms, start_event, stop_event));

  float avg_time_ms = total_time_ms / bench_iters;
  float avg_time_us = avg_time_ms * 1000.0f;

  // Calculate FLOPS
  long long ops = 2LL * qH * qL * kvL * dH * 2LL * BS; // 2 ops per multiply-add
  double gflops = (ops * bench_iters) / (total_time_ms * 1e6);
  double gflops_per_iter = ops / (avg_time_ms * 1e6);

  // Calculate DRAM bandwidth
  long long bytes_per_iter = ((long long)kvH * kvL * dH * 2 * sizeof(GQATester::TypeQKV) + (long long)qH * qL * dH * (sizeof(GQATester::TypeQKV) + sizeof(GQATester::TypeO))) * BS; // Q(bf16) + K(bf16) + V(bf16) + O(bf16)
  float avg_dram_bw_gbps = (bytes_per_iter / (avg_time_ms / 1000.0f)) / (1024.0f * 1024.0f * 1024.0f);

  // Report results
  std::cout << "\n=== Benchmark Results ===" << std::endl;
  std::cout << "Average time per iteration: " << avg_time_ms << " ms (" << avg_time_us << " μs)" << std::endl;
  std::cout << "GFLOPS per iteration: " << gflops_per_iter << std::endl;
  std::cout << "Average DRAM bandwidth: " << avg_dram_bw_gbps << " GB/s" << std::endl;

  // Cleanup
  gpuErrChk(cudaGraphExecDestroy(graph_exec));
  gpuErrChk(cudaGraphDestroy(graph));
  gpuErrChk(cudaEventDestroy(start_event));
  gpuErrChk(cudaEventDestroy(stop_event));
  gpuErrChk(cudaStreamDestroy(stream));

  std::cout << "=== Benchmark Complete ===" << std::endl;
}


int main(int argc, char* argv[]) {
  srand(time(NULL));

  int kvH = 8;     // num KV head
  int qH = 64;     // num Q head
  int qL = 1;      // Q sequence length
  int kvL = 2048;  // KV sequence length
  int dH = 64;     // hidden dimension
  int BS = 1;      // batch size
  float softmax_scale = 1.0f / (float)sqrt(dH);
  int sliding_window_size = 0; // when sliding_window_size = 0, it's disabled
  bool pdl = false;
  // don't support it yet
  int pdl_count = -1;
  // 0: gqa (contiguous KV cache), 1: gqa_paged (paged KV cache)
  int mode = 0;

  // arg parsing
  while (1) {
    static struct option long_options[] = {
    {"kvL",         required_argument, 0, 0},
    {"kvH",         required_argument, 0, 0},
    {"qH",          required_argument, 0, 0},
    {"qL",          required_argument, 0, 0},
    {"BS",          required_argument, 0, 0},
    {"sliding_window_size", required_argument, 0, 0},
    {"mode",        required_argument, 0, 0},
    {0, 0, 0, 0} // denote end of array
    };

    int option_index = 0;
    // M no argument
    // M: required argument
    // M:: optional argument
    int c = getopt_long(argc, argv, "", long_options, &option_index);

    if (c==-1) break;
    switch (c) {
      case 0:
        // Long option
        if (option_index == 0) kvL = atoi(optarg);
        else if (option_index == 1) kvH = atoi(optarg);
        else if (option_index == 2) qH = atoi(optarg);
        else if (option_index == 3) qL = atoi(optarg);
        else if (option_index == 4) BS = atoi(optarg);
        else if (option_index == 5) sliding_window_size = atoi(optarg);
        else if (option_index == 6) mode = atoi(optarg);
        break;
      default: assert(false);
    }
  }

  GQATester tester(kvH, qH, qL, kvL, dH, BS, softmax_scale, sliding_window_size, mode);
  bool success = tester.verify();
  std::cout << "Correctness test"
            << " mode=" << mode
            << " " << (success ? "PASSED" : "FAILED") << std::endl;

  benchmark_gqa(kvH, qH, qL, kvL, dH, BS, softmax_scale, sliding_window_size, mode, pdl, pdl_count, 100, 1000);
}
