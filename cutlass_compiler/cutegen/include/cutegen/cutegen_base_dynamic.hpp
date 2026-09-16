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

#if !defined(CUTEGEN_BASE_DYNAMIC_HPP_INCLUDED_)
#define CUTEGEN_BASE_DYNAMIC_HPP_INCLUDED_

#include "cutegen/cutegen.hpp"
#include "cutegen/cg_error.hpp"
#include "cutegen/cg_int.hpp"
#include "cutegen/underscore.hpp"
#include "cutegen/dynamic.hpp"
#include "cutegen/scaled_basis.hpp"
#include "cutegen/ratio.hpp"
#include "cutegen/rec_var.hpp"
#include "cutegen/rec_var_algorithms.hpp"
#include "cutegen/layout.hpp"
#include "cutegen/composed_layout.hpp"
#include "cutegen/visitors.hpp"

namespace cutegen
{
struct dynamic_traits_t
{
    using dynamic_int_t     = dynamic_t;
    using dynamic_pointer_t = dynamic_ptr_t;
};

using layout          = layout_t<dynamic_traits_t>;
using scaled_basis    = scaled_basis_t<ratio, layout::int_t, dynamic_t>;
using shape           = layout::shape_t;
using stride          = layout::stride_t;
using int_tuple       = cute_int_tuple_t<dynamic_traits_t>;
using coord           = cute_coord_t<dynamic_traits_t>;
using tile            = cute_tile_t<dynamic_traits_t>;
using composed_layout = composed_layout_t<dynamic_traits_t>;

/// Unit basis element, this is repeated for the scaled_basis alias in cutegen_mlir.hpp and this header
template <class... AdditionalModes>
scaled_basis E(scaled_basis::mode_value_t mode0, AdditionalModes... modes)
{
    return scaled_basis::E(mode0, modes...);
}
} // namespace cutegen

#include "cutegen/literals.hpp"
#endif // !defined(CUTEGEN_BASE_DYNAMIC_HPP_INCLUDED_)
