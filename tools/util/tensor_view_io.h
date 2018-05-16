/***************************************************************************************************
* Copyright (c) 2018, NVIDIA CORPORATION.  All rights reserved.
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
#pragma once

#include <cutlass/core_io.h>
#include <cutlass/tensor_view.h>

template <typename T>
inline std::ostream& tensor_view_output(std::ostream& out, T t) {
  out << t;
  return out;
}

template <>
inline std::ostream& tensor_view_output<int8_t>(std::ostream& out, int8_t t) {
  out << int(t);
  return out;
}

template <typename T>
inline std::ostream& operator<<(std::ostream& out, cutlass::TensorView<T> const& tensor) {
  for (int batch = 0; batch < tensor.size(0); ++batch) {
    out << "[\n  ";
    for (int h = 0; h < tensor.size(1); ++h) {
      for (int w = 0; w < tensor.size(2); ++w) {
        for (int c = 0; c < tensor.size(3); ++c) {
          out << ((c | w) ? ", " : "");
          tensor_view_output(out, tensor.at(cutlass::make_Coord(batch, h, w, c)));
        }
      }
      if (h + 1 < tensor.size(1)) {
        out << " ;\n  ";
      }
    }
    out << " ]";
  }

  return out;
}
