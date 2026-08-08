/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Unit tests for device-side SubbyteReference stores.

    Element types whose bit width does not divide the storage unit (the 6-bit types) are
    stored across two storage units, so a store is a read-modify-write over bits shared with
    neighbouring elements. These tests pin the observable contract of that path: a store must
    land exactly, and it must not disturb an element a concurrent thread owns.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/subbyte_reference.h"
#include "cutlass/float_subbyte.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/util/host_tensor.h"

namespace test {
namespace core {

/// Element payload is the low sizeof_bits<Element> bits of the storage byte.
template <typename Element>
CUTLASS_HOST_DEVICE Element element_from_payload(int payload) {
  constexpr int kMask = (1 << cutlass::sizeof_bits<Element>::value) - 1;
  Element e{};
  e.storage = static_cast<decltype(e.storage)>(payload & kMask);
  return e;
}

template <typename Element>
CUTLASS_HOST_DEVICE int payload_of(Element e) {
  constexpr int kMask = (1 << cutlass::sizeof_bits<Element>::value) - 1;
  return static_cast<int>(e.storage) & kMask;
}

/// One thread per element: every store races with the stores to its neighbours.
template <typename Element>
__global__ void scatter_kernel(Element *ptr, int n) {
  int i = int(blockIdx.x) * int(blockDim.x) + int(threadIdx.x);
  if (i < n) {
    cutlass::SubbyteReference<Element> ref(ptr, i);
    ref.set(element_from_payload<Element>(i * 7 + 1));
  }
}

template <typename Element>
__global__ void gather_kernel(int *out, Element *ptr, int n) {
  int i = int(blockIdx.x) * int(blockDim.x) + int(threadIdx.x);
  if (i < n) {
    cutlass::SubbyteReference<Element> ref(ptr, i);
    out[i] = payload_of<Element>(ref.get());
  }
}

/// Single thread walking every offset, so both the one-unit and the straddling branch are
/// exercised deterministically rather than by scheduling luck.
template <typename Element>
__global__ void sweep_kernel(int *out, Element *ptr, int n) {
  if (blockIdx.x != 0 || threadIdx.x != 0) {
    return;
  }
  for (int i = 0; i < n; ++i) {
    cutlass::SubbyteReference<Element> ref(ptr, i);
    ref.set(element_from_payload<Element>(i * 5 + 3));
  }
  for (int i = 0; i < n; ++i) {
    cutlass::SubbyteReference<Element> ref(ptr, i);
    out[i] = payload_of<Element>(ref.get());
  }
}

template <typename Element>
void run_concurrent_test() {
  int const kElements = 4096;

  cutlass::HostTensor<Element, cutlass::layout::RowMajor> data({kElements, 1});
  cutlass::HostTensor<int, cutlass::layout::RowMajor> observed({kElements, 1});

  for (int i = 0; i < kElements; ++i) {
    data.at({i, 0}) = element_from_payload<Element>(0);
    observed.at({i, 0}) = -1;
  }
  data.sync_device();
  observed.sync_device();

  dim3 grid((kElements + 127) / 128, 1);
  dim3 block(128, 1);

  scatter_kernel<Element><<<grid, block>>>(data.device_data(), kElements);
  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  gather_kernel<Element><<<grid, block>>>(observed.device_data(), data.device_data(), kElements);
  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  observed.sync_host();

  int errors = 0;
  for (int i = 0; i < kElements && errors < 8; ++i) {
    int expected = payload_of<Element>(element_from_payload<Element>(i * 7 + 1));
    if (observed.at({i, 0}) != expected) {
      ++errors;
      EXPECT_EQ(observed.at({i, 0}), expected) << "element " << i;
    }
  }
}

template <typename Element>
void run_sweep_test() {
  int const kElements = 256;

  cutlass::HostTensor<Element, cutlass::layout::RowMajor> data({kElements, 1});
  cutlass::HostTensor<int, cutlass::layout::RowMajor> observed({kElements, 1});

  for (int i = 0; i < kElements; ++i) {
    data.at({i, 0}) = element_from_payload<Element>(0);
    observed.at({i, 0}) = -1;
  }
  data.sync_device();
  observed.sync_device();

  sweep_kernel<Element><<<dim3(1, 1), dim3(1, 1)>>>(observed.device_data(), data.device_data(), kElements);
  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  observed.sync_host();

  int errors = 0;
  for (int i = 0; i < kElements && errors < 8; ++i) {
    int expected = payload_of<Element>(element_from_payload<Element>(i * 5 + 3));
    if (observed.at({i, 0}) != expected) {
      ++errors;
      EXPECT_EQ(observed.at({i, 0}), expected) << "element " << i;
    }
  }
}

} // namespace core
} // namespace test

TEST(SubbyteReference, e2m3_device_store_sweep) {
  test::core::run_sweep_test<cutlass::float_e2m3_t>();
}

TEST(SubbyteReference, e3m2_device_store_sweep) {
  test::core::run_sweep_test<cutlass::float_e3m2_t>();
}

TEST(SubbyteReference, e2m3_device_store_concurrent_neighbours) {
  test::core::run_concurrent_test<cutlass::float_e2m3_t>();
}

TEST(SubbyteReference, e3m2_device_store_concurrent_neighbours) {
  test::core::run_concurrent_test<cutlass::float_e3m2_t>();
}
