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

#include "cutlass/cutlass.h"
#include "cute/util/type_traits.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm {

enum class ProducerRoleType {
    None     = 0, // No launch_dependent_grids
    Pdl      = 1, // launch_dependent_grids after running out of work
    EarlyPdl = 2, // launch_dependent_grids right away, ahead of prologue
    Default  = Pdl
};

enum class ConsumerRoleType {
    // WARNING: using None but launching with pdl can produce incorrect results!
    None         = 0, // not a consumer: no report valid, no wait_on_dependent_grids
    Pdl          = 1, // no report valid, just wait_on_dependent_grids
    ReportValidA = 2, // report valid A, no wait_on_dependent_grids
    ReportValidB = 3, // report valid B, no wait_on_dependent_grids
    Default      = Pdl
};

// T::ProducerRole / T::ConsumerRole if defined, else Default.
template <class T, class = void>
struct ProducerRoleOrDefault {
  static constexpr ProducerRoleType value = ProducerRoleType::Default;
};

template <class T>
struct ProducerRoleOrDefault<T, cute::void_t<decltype(T::ProducerRole)>> {
  static constexpr ProducerRoleType value = T::ProducerRole;
};

template <class T, class = void>
struct ConsumerRoleOrDefault {
  static constexpr ConsumerRoleType value = ConsumerRoleType::Default;
};

template <class T>
struct ConsumerRoleOrDefault<T, cute::void_t<decltype(T::ConsumerRole)>> {
  static constexpr ConsumerRoleType value = T::ConsumerRole;
};

}

/////////////////////////////////////////////////////////////////////////////////////////////////
