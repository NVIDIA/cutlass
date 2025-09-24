/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#if defined(CUTLASS_ENABLE_SYCL)
#include <compat/compat.hpp>

#include <vector>
#else
#if defined(__CUDACC__)
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#endif
#endif

#if defined(CUTLASS_ENABLE_SYCL)
// Move to compat ?
namespace cutlass {

  namespace kernel {
    template<typename T>
    void memset(T* ptr, T init_val, std::size_t num_elements) {
      auto global_id = compat::global_id::x();
      if (global_id  < num_elements) {
        ptr[global_id] = init_val;
      }
    }
  }

template <typename T>
class device_vector;

template <typename T>
class host_vector {
  public:
  host_vector(std::size_t num_elements) { vec.resize(num_elements); }
  host_vector(std::size_t num_elements, T init_val) {
    vec = std::move(std::vector<T>(num_elements, init_val));
  }

  T* data() { return vec.data(); }
  T& operator[](std::size_t index) {return vec[index]; }
  std::size_t size() const { return vec.size(); }

  host_vector<T>& operator=(device_vector<T>);
  host_vector(device_vector<T>);

 private:
  std::vector<T> vec;
};

template <typename T>
class device_vector {
  public:
  device_vector(std::size_t num_elements) {
    n_elements = num_elements;
    dev_ptr = make_shared(num_elements);
  }

  device_vector(std::size_t num_elements, T init_value) { 
    n_elements = num_elements;
    dev_ptr = make_shared(num_elements);
    compat::launch<kernel::memset<T>>(sycl::range<1>(num_elements), 
      sycl::range<1>(32), dev_ptr.get(), init_value, num_elements);
    compat::wait_and_throw(); 
  }

  device_vector<T>& operator=(host_vector<T> host_vec);
  device_vector(host_vector<T>);

  T* data() { return dev_ptr.get(); }

  std::size_t size() const {return n_elements; }

 private:
  T* safe_malloc(std::size_t size) {
    T* ptr = compat::malloc<T>(size * sizeof(T));
    if(!ptr) {
      throw std::runtime_error("Allocation Failed.");
    }
    return ptr;
  }
  std::shared_ptr<T> make_shared(std::size_t size) {
    return std::shared_ptr<T>(safe_malloc(size), [=](T* ptr) {
      if (ptr != nullptr) {
        compat::wait_and_throw();
        compat::free(ptr);
      }
    });
  }
  std::shared_ptr<T> dev_ptr;
  std::size_t n_elements;
};

template<typename T>
host_vector<T>& host_vector<T>::operator=(device_vector<T> device_vec) {
    compat::wait_and_throw();
    host_vector host_vec(device_vec.size());
    compat::memcpy(host_vec.data(), device_vec.data(),
                       device_vec.size() * sizeof(T));
    *this = host_vec;
    return *this;
}

template<typename T>
host_vector<T>::host_vector(device_vector<T> device_vec) {
    compat::wait_and_throw();
    host_vector host_vec(device_vec.size());
    compat::memcpy(host_vec.data(), device_vec.data(),
                       device_vec.size() * sizeof(T));
    *this = host_vec;
}

template<typename T>
device_vector<T>& device_vector<T>::operator=(host_vector<T> host_vec) {
    device_vector device_vec(host_vec.size());
    compat::memcpy(device_vec.data(), host_vec.data(), host_vec.size() * sizeof(T));
    compat::wait_and_throw();
    *this = device_vec;
    return *this;
}

template<typename T>
device_vector<T>::device_vector(host_vector<T> host_vec) {
    device_vector device_vec(host_vec.size());
    compat::memcpy(device_vec.data(), host_vec.data(), host_vec.size() * sizeof(T));
    compat::wait_and_throw();
    *this = device_vec;
}

}  // namespace cutlass
#endif

#if defined(CUTLASS_ENABLE_SYCL)
  template<typename T>
  using host_vector = cutlass::host_vector<T>;
  template<typename T>
  using device_vector = cutlass::device_vector<T>;
#else
#if defined(__CUDACC__)
  template<typename T>
  using host_vector = thrust::host_vector<T>;
  template<typename T>
  using device_vector = thrust::device_vector<T>;
#endif
#endif
