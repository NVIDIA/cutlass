/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#pragma once

#include <cuda_runtime.h>

#include <algorithm>
#include <cstdint>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

#include "cutlass/epilogue/thread/activation.h"
#include "cutlass/epilogue/thread/linear_combination_generic_with_scaling.h"
#include "cutlass/gemm/device/gemm_sparse_with_absmax.h"
#include "cutlass/util/host_reorder.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/host_uncompress.h"
#include "cutlass/util/reference/host/tensor_fill.h"

namespace test { namespace gemm { namespace device { namespace sparse_absmax_update {

using Element = cutlass::float_e4m3_t;
using RowMajor = cutlass::layout::RowMajor;
using ColumnMajor = cutlass::layout::ColumnMajor;
using OutputOp = cutlass::epilogue::thread::LinearCombinationGenericWithScalingAndAbsMax<
    cutlass::epilogue::thread::ReLu, Element, Element, 8, float, float>;
using Gemm = cutlass::gemm::device::SparseGemmWithAbsmax<
    Element, RowMajor, Element, ColumnMajor, Element, RowMajor,
    float, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm89,
    cutlass::gemm::GemmShape<128, 64, 128>,
    cutlass::gemm::GemmShape<64, 32, 128>,
    cutlass::gemm::GemmShape<16, 8, 64>, OutputOp,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    3, 16, 16, false, cutlass::arch::OpMultiplyAdd>;

constexpr int kM = 256;
constexpr int kN = 128;
constexpr int kK = 256;
constexpr int kElements = kM * kN;
constexpr int kTileRows = kM / Gemm::ThreadblockShape::kM;
constexpr int kGuard = 128;  // Preserves alignment of the interior allocation.
constexpr float kSentinel = -16.0f;
constexpr float kAlpha = 0.125f;
constexpr float kBeta = 0.5f;

void cuda_check(cudaError_t status, char const* operation) {
  if (status != cudaSuccess) {
    throw std::runtime_error(std::string(operation) + ": " + cudaGetErrorString(status));
  }
}

void cutlass_check(cutlass::Status status, char const* operation) {
  if (status != cutlass::Status::kSuccess) {
    throw std::runtime_error(std::string(operation) + ": " + cutlass::cutlassGetStatusString(status));
  }
}

// Guarded outputs also reveal writes that are inside a live allocation but outside
// its logical output. CUDA allocations themselves remain live throughout a case.
class Buffer {
 public:
  explicit Buffer(int count) : count_(count) {
    cuda_check(cudaMalloc(reinterpret_cast<void**>(&allocation_),
                          (count_ + 2 * kGuard) * sizeof(Element)), "cudaMalloc");
  }
  ~Buffer() { cudaFree(allocation_); }
  Buffer(Buffer const&) = delete;
  Buffer& operator=(Buffer const&) = delete;

  Element* data() const { return allocation_ + kGuard; }

  void reset() {
    std::vector<Element> host(count_ + 2 * kGuard, Element(kSentinel));
    upload_all(host);
  }

  void set_payload(std::vector<Element> const& payload) {
    if (int(payload.size()) != count_) throw std::runtime_error("buffer size mismatch");
    std::vector<Element> host(count_ + 2 * kGuard, Element(kSentinel));
    std::copy(payload.begin(), payload.end(), host.begin() + kGuard);
    upload_all(host);
  }

  std::vector<Element> snapshot() const {
    std::vector<Element> host(count_ + 2 * kGuard);
    cuda_check(cudaMemcpy(host.data(), allocation_, host.size() * sizeof(Element),
                          cudaMemcpyDeviceToHost), "download buffer");
    return host;
  }

  int guard_changes(std::vector<Element> const& host) const {
    int changed = 0;
    for (int i = 0; i < kGuard; ++i) {
      changed += float(host[i]) != kSentinel;
      changed += float(host[kGuard + count_ + i]) != kSentinel;
    }
    return changed;
  }

  int payload_changes(std::vector<Element> const& host) const {
    int changed = 0;
    for (int i = 0; i < count_; ++i) changed += float(host[kGuard + i]) != kSentinel;
    return changed;
  }

 private:
  void upload_all(std::vector<Element> const& host) {
    cuda_check(cudaMemcpy(allocation_, host.data(), host.size() * sizeof(Element),
                          cudaMemcpyHostToDevice), "upload buffer");
  }
  int count_;
  Element* allocation_ = nullptr;
};

int mismatch_count(std::vector<Element> const& actual,
                   std::vector<Element> const& expected, char const* label) {
  int count = 0;
  int first = -1;
  for (int i = 0; i < kElements; ++i) {
    if (float(actual[kGuard + i]) != float(expected[i])) {
      if (first < 0) first = i;
      ++count;
    }
  }
  if (first >= 0) {
    std::cout << "    " << label << " first mismatch (" << first / kN << ','
              << first % kN << "): actual=" << float(actual[kGuard + first])
              << " expected=" << float(expected[first]) << '\n';
  }
  return count;
}

struct Inputs {
  using ElementE = Gemm::ElementE;
  cutlass::HostTensor<Element, RowMajor> a;
  cutlass::HostTensor<Element, RowMajor> dense_a;
  cutlass::HostTensor<Element, ColumnMajor> b;
  cutlass::HostTensor<Element, RowMajor> c;
  cutlass::HostTensor<ElementE, RowMajor> metadata;
  cutlass::HostTensor<ElementE, Gemm::LayoutE> reordered_metadata;
  std::vector<float> accumulators;

  Inputs() : accumulators(kElements, 0.0f) {
    int metadata_columns = kK / Gemm::kSparse / Gemm::kElementsPerElementE;
    a.resize({kM, kK / Gemm::kSparse});
    dense_a.resize({kM, kK}, false);
    b.resize({kK, kN});
    c.resize({kM, kN});
    metadata.resize({kM, metadata_columns}, false);
    reordered_metadata.resize({kM, metadata_columns});

    // Small binary fractions keep dot products and all reference outputs exactly
    // representable. Both signs exercise ReLU and the pre-activation auxiliary.
    for (int m = 0; m < kM; ++m) {
      for (int k = 0; k < kK / Gemm::kSparse; ++k) {
        a.host_view().at({m, k}) = Element((m & 1) ? -0.25f : 0.25f);
      }
      for (int n = 0; n < kN; ++n) c.host_view().at({m, n}) = Element(0.5f);
    }
    for (int k = 0; k < kK; ++k) {
      for (int n = 0; n < kN; ++n) {
        b.host_view().at({k, n}) = Element((n & 1) ? -0.25f : 0.25f);
      }
    }

    // Use the same legal sparse-metadata generation/reordering utilities as the
    // repository's sparse GEMM testbed, rather than hand-encoding instruction E.
    cutlass::reference::host::TensorFillRandomSparseMeta(
        metadata.host_view(), 7, Gemm::kMetaSizeInBits);
    cutlass::reorder_meta(reordered_metadata.host_ref(), metadata.host_ref(),
                         {kM, kN, metadata_columns});
    cutlass::uncompress(dense_a.host_ref(), a.host_ref(), metadata.host_ref(), kM, kK);

    for (int m = 0; m < kM; ++m) {
      for (int n = 0; n < kN; ++n) {
        for (int k = 0; k < kK; ++k) {
          accumulators[m * kN + n] += float(dense_a.host_view().at({m, k})) *
                                      float(b.host_view().at({k, n}));
        }
        float analytic = ((m ^ n) & 1) ? -8.0f : 8.0f;
        if (accumulators[m * kN + n] != analytic) {
          throw std::runtime_error("host sparse-input control failed");
        }
      }
    }
    a.sync_device();
    b.sync_device();
    c.sync_device();
    reordered_metadata.sync_device();
  }

  Gemm::Arguments arguments(Buffer& d, Element* aux, Element* bias, int ldr) {
    OutputOp::Params output;
    output.activation.alpha = kAlpha;
    output.activation.beta = kBeta;
    return Gemm::Arguments({kM, kN, kK}, a.device_ref(), b.device_ref(), c.device_ref(),
                           {d.data(), RowMajor(kN)},
                           reordered_metadata.device_ref(), {aux, RowMajor(kN)},
                           bias, ldr, output, 1);
  }

  std::vector<Element> expected(std::vector<Element> const* bias, int ldr,
                                bool auxiliary) const {
    std::vector<Element> result(kElements);
    for (int m = 0; m < kM; ++m) {
      for (int n = 0; n < kN; ++n) {
        int tile_row = m / Gemm::ThreadblockShape::kM;
        float bias_value = bias ? float(bias->at(tile_row * ldr + n)) : 0.0f;
        float aux = kAlpha * accumulators[m * kN + n] + kBeta * 0.5f + bias_value;
        result[m * kN + n] = Element(auxiliary ? aux : std::max(aux, 0.0f));
      }
    }
    return result;
  }
};

struct Case {
  char const* name;
  bool replace_aux;
  bool replace_bias;
  int old_ldr;
  int new_ldr;
  bool old_aux = true;
  bool new_aux = true;
  bool old_bias = true;
  bool new_bias = true;
};

Case const kCases[] = {
    {"unchanged_control", false, false, 0, 0},
    {"aux_pointer", true, false, 0, 0},
    {"bias_pointer", false, true, 0, 0},
    {"bias_stride", false, false, 0, kN},
    {"combined", true, true, 0, kN},
    {"enable_aux", true, false, 0, 0, false, true},
    {"disable_aux", false, false, 0, 0, true, false},
    {"enable_bias", false, false, 0, 0, true, true, false, true},
    {"disable_bias", false, false, 0, 0, true, true, true, false},
};

void run_and_wait(Gemm& op) {
  cutlass_check(op.run(), "run");
  cuda_check(cudaDeviceSynchronize(), "synchronize GEMM");
}

bool run_case(Inputs& inputs, Case const& test) {
  std::cout << "CASE " << test.name << '\n';
  Buffer old_d(kElements), updated_d(kElements), fresh_d(kElements);
  Buffer old_aux(kElements), new_aux(kElements), fresh_aux(kElements);
  Buffer old_bias(kTileRows * kN), new_bias(kTileRows * kN);
  std::vector<Element> old_bias_values(kTileRows * kN);
  std::vector<Element> new_bias_values(kTileRows * kN);
  for (int row = 0; row < kTileRows; ++row) {
    for (int n = 0; n < kN; ++n) {
      old_bias_values[row * kN + n] = Element(row == 0 ? 0.5f : -0.5f);
      new_bias_values[row * kN + n] = Element(row == 0 ? -0.5f : 0.5f);
    }
  }
  old_bias.set_payload(old_bias_values);
  new_bias.set_payload(new_bias_values);
  auto old_bias_before = old_bias.snapshot();
  auto new_bias_before = new_bias.snapshot();
  auto reset_outputs = [&] {
    old_d.reset(); updated_d.reset(); fresh_d.reset();
    old_aux.reset(); new_aux.reset(); fresh_aux.reset();
  };
  reset_outputs();

  Gemm reused;
  auto initial = inputs.arguments(old_d, test.old_aux ? old_aux.data() : nullptr,
                                  test.old_bias ? old_bias.data() : nullptr, test.old_ldr);
  cutlass_check(Gemm::can_implement(initial), "can_implement initial");
  cutlass_check(reused.initialize(initial), "initialize reused operator");
  run_and_wait(reused);

  auto initial_d = old_d.snapshot();
  auto initial_aux = old_aux.snapshot();
  auto initial_bias = test.old_bias ? &old_bias_values : nullptr;
  int initial_errors = mismatch_count(initial_d, inputs.expected(initial_bias, test.old_ldr, false),
                                       "initial D");
  initial_errors += test.old_aux
      ? mismatch_count(initial_aux, inputs.expected(initial_bias, test.old_ldr, true), "initial Aux")
      : old_aux.payload_changes(initial_aux);
  initial_errors += old_d.guard_changes(initial_d) + old_aux.guard_changes(initial_aux);
  if (initial_errors) throw std::runtime_error("initial GPU/host control failed; not an update result");

  // Discard all baseline output, then use independent output allocations for the
  // fresh operator. Neither path can accidentally inherit a correct prior result.
  reset_outputs();
  Buffer& target_aux = test.replace_aux ? new_aux : old_aux;
  Buffer& inactive_aux = test.replace_aux ? old_aux : new_aux;
  Buffer& target_bias = test.replace_bias ? new_bias : old_bias;
  auto target_bias_host = test.new_bias
      ? (test.replace_bias ? &new_bias_values : &old_bias_values) : nullptr;
  auto updated_args = inputs.arguments(updated_d, test.new_aux ? target_aux.data() : nullptr,
                                       test.new_bias ? target_bias.data() : nullptr, test.new_ldr);
  auto fresh_args = updated_args;
  fresh_args.ref_D = {fresh_d.data(), RowMajor(kN)};
  fresh_args.ref_Aux = {test.new_aux ? fresh_aux.data() : nullptr, RowMajor(kN)};

  Gemm fresh;
  cutlass_check(Gemm::can_implement(fresh_args), "can_implement fresh");
  cutlass_check(fresh.initialize(fresh_args), "initialize fresh operator");
  run_and_wait(fresh);
  auto expected_d = inputs.expected(target_bias_host, test.new_ldr, false);
  auto expected_aux = inputs.expected(target_bias_host, test.new_ldr, true);
  auto fresh_d_host = fresh_d.snapshot();
  auto fresh_aux_host = fresh_aux.snapshot();
  int fresh_errors = mismatch_count(fresh_d_host, expected_d, "fresh D");
  fresh_errors += test.new_aux ? mismatch_count(fresh_aux_host, expected_aux, "fresh Aux")
                               : fresh_aux.payload_changes(fresh_aux_host);
  fresh_errors += fresh_d.guard_changes(fresh_d_host) + fresh_aux.guard_changes(fresh_aux_host);
  if (fresh_errors) throw std::runtime_error("fresh GPU/host control failed; not an update result");

  cutlass_check(reused.update(updated_args), "update");
  run_and_wait(reused);
  auto d_host = updated_d.snapshot();
  auto aux_host = target_aux.snapshot();
  auto inactive_aux_host = inactive_aux.snapshot();
  auto old_d_host = old_d.snapshot();
  auto old_bias_after = old_bias.snapshot();
  auto new_bias_after = new_bias.snapshot();
  int d_errors = mismatch_count(d_host, expected_d, "updated D");
  int aux_errors = test.new_aux ? mismatch_count(aux_host, expected_aux, "updated Aux")
                               : target_aux.payload_changes(aux_host);
  int stale_writes = inactive_aux.payload_changes(inactive_aux_host) + old_d.payload_changes(old_d_host);
  int guard_errors = updated_d.guard_changes(d_host) + target_aux.guard_changes(aux_host) +
      inactive_aux.guard_changes(inactive_aux_host) + old_d.guard_changes(old_d_host);
  bool bias_changed = old_bias_after != old_bias_before || new_bias_after != new_bias_before;
  bool passed = !(d_errors || aux_errors || stale_writes || guard_errors || bias_changed);
  std::cout << "    initial and fresh controls: PASS\n"
            << "    D mismatches=" << d_errors << " Aux mismatches/unexpected writes=" << aux_errors
            << " stale-output writes=" << stale_writes << " guard changes=" << guard_errors
            << " bias modified=" << bias_changed << '\n'
            << "    " << (passed ? "PASS" : "FAIL") << '\n';
  return passed;
}

}}}}  // namespace test::gemm::device::sparse_absmax_update
