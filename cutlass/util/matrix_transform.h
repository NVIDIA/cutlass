/******************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#pragma once

/**
 * \file
 * \brief Enumeration of dense matrix view transformations
 */

#include "printable.h"

namespace cutlass {


/******************************************************************************
 * matrix_transform_t
 ******************************************************************************/

/**
 * \brief Enumeration of dense matrix view transformations
 *
 * These enumerators (and corresponding tag types) describe which view
 * transformation needs to be applied prior to operation upon a given dense
 * matrix. Its values correspond to Fortran characters 'n' (non-transpose),
 * 't'(transpose) and 'c'(conjugate transpose) that are often
 * used as parameters to legacy BLAS implementations
 */
struct matrix_transform_t : printable_t
{
    /// \brief Enumerants (same as CUBLAS)
    enum kind_t
    {
        /// Invalid view
        Invalid             = -1,

        /// Non-transpose view
        NonTranspose        = 0,

        /// Transpose view
        Transpose           = 1,

        /// Conjugate transpose view
        ConjugateTranpose   = 2,
    };

    /// Enumerant value
    kind_t kind;

    /// Default constructor
    matrix_transform_t() : kind(Invalid) {}

    /// Copy constructor
    matrix_transform_t(const kind_t &other_kind) : kind(other_kind) {}

    /// Cast to kind_t
    operator kind_t() const { return kind; }

    /// Returns the instance as a string
    __host__ __device__ inline
    char const* to_string() const
    {
        switch (kind)
        {
            case NonTranspose:      return "NonTranspose";
            case Transpose:         return "Transpose";
            case ConjugateTranpose: return "ConjugateTranpose";
            default:                return "Invalid";
        }
    }

    /// Insert the formatted instance into the output stream
    void print(std::ostream& out) const { out << to_string(); }

};


} // namespace cutlass
