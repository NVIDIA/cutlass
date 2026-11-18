/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/numeric_conversion.h"
#include "cutlass/epilogue/fusion/callbacks.hpp"

namespace cutlass::epilogue::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <class Op>
struct with_pzo_rounding {
  static_assert(cutlass::detail::dependent_false<Op>,
    "Unrecognized fusion operation. Extend with_pzo_rounding.");
};

template <template <class, FloatRoundStyle> class Op,
          class T0, FloatRoundStyle R>
struct with_pzo_rounding<Op<T0, R>> {
  static_assert(R == FloatRoundStyle::round_to_nearest,
    "PZO canonicalization is only implemented for round_to_nearest round style.");
  using type = Op<T0, FloatRoundStyle::round_to_nearest_pzo>;
};

template <template <class, class, FloatRoundStyle> class Op,
          class T0, class T1, FloatRoundStyle R>
struct with_pzo_rounding<Op<T0, T1, R>> {
  static_assert(R == FloatRoundStyle::round_to_nearest,
    "PZO canonicalization is only implemented for round_to_nearest round style.");
  using type = Op<T0, T1, FloatRoundStyle::round_to_nearest_pzo>;
};

template <template <class, class, class, FloatRoundStyle> class Op,
          class T0, class T1, class T2, FloatRoundStyle R>
struct with_pzo_rounding<Op<T0, T1, T2, R>> {
  static_assert(R == FloatRoundStyle::round_to_nearest,
    "PZO canonicalization is only implemented for round_to_nearest round style.");
  using type = Op<T0, T1, T2, FloatRoundStyle::round_to_nearest_pzo>;
};

template <template <class, class, class, class, FloatRoundStyle> class Op,
          class T0, class T1, class T2, class T3, FloatRoundStyle R>
struct with_pzo_rounding<Op<T0, T1, T2, T3, R>> {
  static_assert(R == FloatRoundStyle::round_to_nearest,
    "PZO canonicalization is only implemented for round_to_nearest round style.");
  using type = Op<T0, T1, T2, T3, FloatRoundStyle::round_to_nearest_pzo>;
};

template <template <class, class, class, class, class, FloatRoundStyle> class Op,
          class T0, class T1, class T2, class T3, class T4, FloatRoundStyle R>
struct with_pzo_rounding<Op<T0, T1, T2, T3, T4, R>> {
  static_assert(R == FloatRoundStyle::round_to_nearest,
    "PZO canonicalization is only implemented for round_to_nearest round style.");
  using type = Op<T0, T1, T2, T3, T4, FloatRoundStyle::round_to_nearest_pzo>;
};

template <class T>
struct with_pzo_fusion_arg {
  using type = T;
};

template <class DispatchPolicy, class Operation, class CtaTile_MNK, class EpilogueTile_MN,
          class... Args>
struct with_pzo_fusion_arg<
    fusion::FusionCallbacks<DispatchPolicy, Operation, CtaTile_MNK, EpilogueTile_MN, Args...>> {
  using type = fusion::FusionCallbacks<
      DispatchPolicy, typename with_pzo_rounding<Operation>::type, CtaTile_MNK, EpilogueTile_MN,
      Args...>;
};

template <class CollectiveEpilogue>
struct with_pzo_fusion {
  static_assert(cutlass::detail::dependent_false<CollectiveEpilogue>,
    "Invalid collective epilogue instantiation passed to with_pzo_fusion.");
};

template <template <class...> class Collective, class... Ts>
struct with_pzo_fusion<Collective<Ts...>> {
  using type = Collective<typename with_pzo_fusion_arg<Ts>::type...>;
  static_assert(not cute::is_same_v<type, Collective<Ts...>>,
    "Invalid collective epilogue instantiation passed to with_pzo_fusion.");
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// Utility for converting an already-instantiated collective epilogue to one that canonicalizes 0s.
// Kernels that produce data for a data-driven-sync consumer should never producer negative zeros,
// which is the sentinel value.
template <
  class CollectiveEpilogue_,
  bool IsDataDrivenSyncConsumer
>
struct make_dependency_tracking {
  using Epilogue = CollectiveEpilogue_;
};

// Data-driven sync consumer specialization
template <class CollectiveEpilogue_>
struct make_dependency_tracking<CollectiveEpilogue_, true> {
  using Epilogue = typename detail::with_pzo_fusion<CollectiveEpilogue_>::type;
};

} // namespace detail

template <
  class CollectiveEpilogue_,
  bool IsDataDrivenSyncConsumer
>
using make_dependency_tracking =
    typename detail::make_dependency_tracking<CollectiveEpilogue_, IsDataDrivenSyncConsumer>::Epilogue;

} // namespace cutlass::epilogue::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
