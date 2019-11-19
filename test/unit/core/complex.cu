/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Statically sized array of elements that accommodates all CUTLASS-supported numeric types
           and is safe to use in a union.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/complex.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/util/device_memory.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(complex, f64_to_f32_conversion) {

  cutlass::complex<double> source = {1.5, -1.25};

  cutlass::complex<float> dest = cutlass::complex<float>(source); // explicit conversion

  EXPECT_TRUE(source.real() == 1.5 && source.imag() == -1.25 && 
    dest.real() == 1.5f && dest.imag() == -1.25f);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(complex, f32_to_f64_conversion) {

  cutlass::complex<float> source = {-1.5f, 1.25f};

  cutlass::complex<double> dest = source;  // implicit conversion

  EXPECT_TRUE(source.real() == -1.5f && source.imag() == 1.25f && 
    dest.real() == -1.5 && dest.imag() == 1.25);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(complex, s32_to_f64_conversion) {

  cutlass::complex<int> source = {-2, 1};

  cutlass::complex<double> dest = source;  // implicit conversion

  EXPECT_TRUE(source.real() == -2 && source.imag() == 1 && 
    dest.real() == -2 && dest.imag() == 1);
}


/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(complex, f16_to_f32_conversion) {

  cutlass::complex<cutlass::half_t> source = {1.5_hf, -1.25_hf};

  cutlass::complex<float> dest = cutlass::complex<float>(source); // explicit conversion

  EXPECT_TRUE(source.real() == 1.5_hf && source.imag() == -1.25_hf && 
    dest.real() == 1.5f && dest.imag() == -1.25f);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
