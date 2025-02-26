/***************************************************************************************************
 * Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Process the input&output data in Flash MLA kernels
*/

#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>
#include <thrust/iterator/counting_iterator.h>

template <typename T>
struct fill_nan_functor {
    T* blocked_k;
    const int* cache_seqlens;
    int max_seqlen_pad, h_kv, d;
    
    __host__ __device__
    fill_nan_functor(T* bk, const int* cs, int msp, int hkv, int dd) :
        blocked_k(bk), cache_seqlens(cs), max_seqlen_pad(msp), h_kv(hkv), d(dd) {}
    
    __host__ __device__
    void operator()(int idx) {
        auto NAN_VALUE = std::numeric_limits<T>::quiet_NaN();
        int h_d_size = h_kv * d;
        int seq_h_d_size = max_seqlen_pad * h_d_size;
        
        int batch_idx = idx / seq_h_d_size;
        int pos_in_seq = (idx % seq_h_d_size) / h_d_size;
        
        if (pos_in_seq >= cache_seqlens[batch_idx]) {
            blocked_k[idx] = NAN_VALUE;  // NaN
        }
    }
};

template <typename T>
void fill_nan(
    T* d_blocked_k,
    const int* d_cache_seqlens,
    int b, int max_seqlen_pad, int h_kv, int d
) {
    int total_elements = b * max_seqlen_pad * h_kv * d;
    
    thrust::for_each(
        thrust::device,
        thrust::counting_iterator<int>(0),
        thrust::counting_iterator<int>(total_elements),
        fill_nan_functor(d_blocked_k, d_cache_seqlens, max_seqlen_pad, h_kv, d)
    );
}