/***************************************************************************************************
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

#pragma once

#include <cute/tensor_impl.hpp>                // cute::Tensor

namespace cute
{

//
// SubgroupTensor
//
// A SubgroupTensor represents a subgroup-scope tensor,
//   e.g. the result of a block 2D load, or an input/output matrix to DPAS.
//
// SubgroupTensor wraps a standard CuTe rmem tensor ("fragment") holding the current
//   work-item's slice of the tensor. It implicitly decays to this fragment, so it can
//   be used as a regular rmem Tensor.
//
// In addition, a SubgroupTensor holds a thread-value layout identifying logical coordinates
//   for each element of the tensor. The interpretation of the logical coordinates is user-defined,
//   Reorder operations use these logical coordinates to identify corresponding values in
//   the source and destination tensors.
//

template <class Engine,
          class Layout,               // fragment coord -> V
          class SubgroupTVLayout>     // (T,V) -> coord in subgroup
struct SubgroupTensor : Tensor<Engine, Layout>
{
  using Base = Tensor<Engine, Layout>;

  using typename Base::iterator;
  using typename Base::value_type;
  using typename Base::element_type;
  using typename Base::reference;
  using typename Base::engine_type;
  using typename Base::layout_type;

  CUTE_HOST_DEVICE constexpr
  SubgroupTensor() {}

  CUTE_HOST_DEVICE constexpr explicit
  SubgroupTensor(Base const& base) {
    *this = static_cast<SubgroupTensor const&>(base);
  }

  static constexpr int rank  = Layout::rank;

  CUTE_HOST_DEVICE constexpr
  decltype(auto)
  tensor() const {
    return *static_cast<const Base*>(this);
  }

  CUTE_HOST_DEVICE constexpr
  auto
  tv_layout() const {
    return SubgroupTVLayout{};
  }
};

template <class Engine, class Layout, class SubgroupTVLayout>
struct is_tensor<SubgroupTensor<Engine,Layout,SubgroupTVLayout>> : true_type {};

template<class Engine,
         class Layout,
         class SubgroupTVLayout,
         __CUTE_REQUIRES(is_layout<SubgroupTVLayout>::value)>
CUTE_HOST_DEVICE
constexpr auto
make_subgroup_tensor(Tensor<Engine, Layout> const& tensor, SubgroupTVLayout const&)
{
  static_assert(is_static_v<SubgroupTVLayout>, "Subgroup TV layout must be static");
  static_assert(is_rmem_v<Engine>, "Expected an rmem tensor");
  return static_cast<SubgroupTensor<Engine,Layout,SubgroupTVLayout> const&>(tensor);
}


//
// Display utilities
//

template <class Engine, class Layout, class SubgroupTVLayout>
CUTE_HOST_DEVICE void print(SubgroupTensor<Engine,Layout,SubgroupTVLayout> const& tensor)
{
  print("SubgroupTensor\n");
  print("  Tensor:           "); print(static_cast<Tensor<Engine,Layout> const&>(tensor)); print("\n");
  print("  SubgroupTVLayout: "); print(SubgroupTVLayout{}); print("\n");
}

} // end namespace cute

