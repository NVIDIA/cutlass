/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Unit tests for thread-level GEMM
*/

#include "../../common/cutlass_unit_test.h"

#include "cutlass/epilogue/thread/linear_combination.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(Epilogue_thread_linear_combination, device_side_f16_f32_value) {

  using Element = float;
  using ElementOutput = cutlass::half_t;
  int const kCount = 8;

  using LinearCombination = cutlass::epilogue::thread::LinearCombination<
    ElementOutput, 
    kCount,
    Element, 
    Element>;

  Element alpha = Element(2);
  Element beta = Element(1);

  typename LinearCombination::Params params(alpha, beta);

  LinearCombination linear_combination_op(params);

  cutlass::Array<ElementOutput, kCount> source;
  cutlass::Array<Element, kCount> accum;

  for (int i = 0; i < kCount; ++i) {
    accum[i] = Element(i * 2);
    source[i] = ElementOutput((i * 7 % 9) - 4);
  }

  cutlass::Array<ElementOutput, kCount> destination = linear_combination_op(accum, source);

  for (int i = 0; i < kCount; ++i) {
    
    ElementOutput expected = ElementOutput(
      alpha * accum[i] + 
      beta * Element(ElementOutput(source[i]))
    );

    ElementOutput got = destination[i];
    
    EXPECT_TRUE(expected == got);
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(Epilogue_thread_linear_combination, device_side_f16_f32_ptr) {

  using Element = float;
  using ElementOutput = cutlass::half_t;
  int const kCount = 8;

  using LinearCombination = cutlass::epilogue::thread::LinearCombination<
    ElementOutput, 
    kCount,
    Element, 
    Element>;

  Element alpha = Element(2);
  Element beta = Element(1);

  typename LinearCombination::Params params(&alpha, &beta);

  LinearCombination linear_combination_op(params);

  cutlass::Array<ElementOutput, kCount> source;
  cutlass::Array<Element, kCount> accum;

  for (int i = 0; i < kCount; ++i) {
    accum[i] = Element(i * 2);
    source[i] = ElementOutput((i * 7 % 9) - 4);
  }

  cutlass::Array<ElementOutput, kCount> destination = linear_combination_op(accum, source);

  for (int i = 0; i < kCount; ++i) {
    
    ElementOutput expected = ElementOutput(
      alpha * accum[i] + 
      beta * Element(ElementOutput(source[i]))
    );

    ElementOutput got = destination[i];
    
    EXPECT_TRUE(expected == got);
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
