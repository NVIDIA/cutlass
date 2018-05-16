/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Host-side implementation of useful operations
*/

#pragma once

#include <cutlass/cutlass.h>
#include <cutlass/tensor_view.h>
#include <tools/util/type_traits.h>

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename SrcType, typename DstType>
struct Cast {
  static inline DstType apply(SrcType src) { return static_cast<DstType>(src); };
};

template <>
struct Cast<float, int8_t> {
  static inline int8_t apply(float src) {
    return static_cast<int8_t>(fmaxf(-128.f, fminf(127.f, src)));
  };
};

template <>
struct Cast<float, uint8_t> {
  static inline uint8_t apply(float src) {
    return static_cast<uint8_t>(fmaxf(0.f, fminf(255.f, src)));
  };
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T>
class HostTensorView : public TensorView<T> {
 public:
  /// Base class
  typedef TensorView<T> TensorView_t;

  /// Convention: depth is the first dimension
  static int const Dim_D = 0;

  /// Convention: height is the second dimension
  static int const Dim_H = 1;

  /// Convention: width is the third dimension
  static int const Dim_W = 2;

  /// Convention: channel is the second dimension
  static int const Dim_C = 3;

  /// Rank of tensor
  static int const Rank = TensorView_t::Rank;

  /// Type used to compute the offset of an element to the base of a tensor
  typedef typename TensorView_t::Offset_t Offset_t;

  /// Reference and stride
  typedef typename TensorView_t::TensorRef_t TensorRef_t;

  /// Coordinate into tensor
  typedef typename TensorView_t::Coord_t Coord_t;

 public:
  //
  // Device and Host Methods
  //

  /// Default constructor
  HostTensorView() {}

  /// Constructs a Tensor_view from a TensorRef and size
  HostTensorView(TensorRef_t const& _ref, Coord_t const& _size) : TensorView_t(_ref, _size) {}

  /// Accesses the size
  Coord_t const& size() const { return TensorView_t::size(); }

  /// Accesses the size of a specified dimension
  int size(int dim) const { return size().at(dim); }

  /// Accesses the stride
  Coord_t const& stride() const { return TensorView_t::stride(); }

  /// Accesses the stride along a specified dimension
  int stride(int dim) const { return stride().at(dim); }

  /// Returns the number of scalar elements needed to store tensor
  size_t capacity() const { return size(3) * stride(3) * stride(2) * stride(1) * stride(0); }

  /// Returns true if the Tensor_view is bound to some memory
  bool good() const { return TensorView_t::good(); }

  /// Updates the reference and size of a TensorView object
  void reset(TensorRef_t const& _ref = TensorRef_t(0), Coord_t const& _size = Coord_t()) {
    return TensorView_t::reset(_ref, _size);
  }

  /// Accesses the tensor reference pointing to data
  TensorRef_t& ref() { return TensorView_t::ref(); }

  /// Accesses the tensor reference pointing to data
  TensorRef_t const& ref() const { return TensorView_t::ref(); }

  /// Assigns a tensor view
  HostTensorView& operator=(TensorView_t const& _tensor) {
    reset(_tensor.ref(), _tensor.size());
    return *this;
  }

  /// Returns the index of an element
  Offset_t offset(Coord_t const& coord) const { return TensorView_t::offset(coord); }

  /// Determines whether a location is within a tensor
  bool contains(Coord_t const& coord) const { return TensorView_t::contains(coord); }

  /// Element-wise accessor
  T& at(Coord_t const& coord) const { return TensorView_t::at(coord); }

  /// Element-wise accessor
  T& operator[](Coord_t const& coord) const { return at(coord); }

  /// Accesses an element with a raw offset
  T& at(int idx) const { return TensorView_t::at(idx); }

  /// Accesses an element with a raw offset
  T& operator[](int idx) const { return at(idx); }

  /// Returns a Tensor_view given location and size quantities
  TensorView_t subview(Coord_t const& location, Coord_t size) const {
    return TensorView_t::subview(location, size);
  }

  /// Recurses through all dimensions and applies a unary operation in place
  template <typename F>
  void elementwise_in_place(F& op, int dim = 0, Offset_t dst_offset_base = 0) {
    Offset_t dst_offset = dst_offset_base;

    for (int idx = 0; idx < size(dim); ++idx, dst_offset += stride(dim)) {
      if (dim < Rank - 1) {
        elementwise_in_place(op, dim + 1, dst_offset);
      } else {
        op(ref().data()[dst_offset]);
      }
    }
  }

  /// Recurses through all dimensions and applies a unary operator with no arguments
  template <typename F>
  void elementwise_stream(F& op, int dim = 0, Offset_t dst_offset_base = 0) {
    Offset_t dst_offset = dst_offset_base;

    for (int idx = 0; idx < size(dim); ++idx, dst_offset += stride(dim)) {
      if (dim < Rank - 1) {
        elementwise_stream(op, dim + 1, dst_offset);
      } else {
        ref().data()[dst_offset] = op();
      }
    }
  }

  /// Recurses through all dimensions and applies a unary operator, supplying the logical
  /// coordinate within the tensor as an argument
  template <typename F>
  void elementwise_generate(F& op,
                            int dim = 0,
                            Offset_t dst_offset_base = 0,
                            Coord_t coord = Coord_t(0)) {
    Offset_t dst_offset = dst_offset_base;

    for (int idx = 0; idx < size(dim); ++idx, dst_offset += stride(dim)) {
      coord.at(dim) = idx;

      if (dim < Rank - 1) {
        elementwise_generate(op, dim + 1, dst_offset, coord);
      } else {
        ref().data()[dst_offset] = op(coord);
      }
    }
  }

  /// Recurses through all dimensions and applies a unary operator, supplying the logical
  /// coordinate within the tensor as an argument
  template <typename F>
  void elementwise_visit(F& op,
                         int dim = 0,
                         Offset_t dst_offset_base = 0,
                         Coord_t coord = Coord_t(0)) const {
    Offset_t dst_offset = dst_offset_base;

    for (int idx = 0; idx < size(dim); ++idx, dst_offset += stride(dim)) {
      coord.at(dim) = idx;

      if (dim < Rank - 1) {
        elementwise_visit(op, dim + 1, dst_offset, coord);
      } else {
        op(ref().data()[dst_offset], coord);
      }
    }
  }

  /// Recurses through all dimensions and applies a binary operation
  template <typename Src, typename F>
  bool elementwise_in_place(F& op,
                            TensorView<Src> const& tensor,
                            int dim = 0,
                            Offset_t dst_offset_base = 0,
                            Offset_t src_offset_base = 0) {
    Offset_t dst_offset = dst_offset_base;
    Offset_t src_offset = src_offset_base;

    if (size().at(dim) != tensor.size().at(dim)) {
      return false;
    }

    for (int idx = 0; idx < size(dim);
         ++idx, dst_offset += stride(dim), src_offset += tensor.stride(dim)) {
      if (dim < Rank - 1) {
        elementwise_in_place(op, tensor, dim + 1, dst_offset, src_offset);
      } else {
        op(data()[dst_offset], tensor.data()[src_offset]);
      }
    }

    return true;
  }

  template <typename Src>
  struct LambdaBinaryAddition {
    void operator()(T& a, Src b) const { a += T(b); }
  };

  template <typename Src>
  struct LambdaBinarySubtraction {
    void operator()(T& a, Src b) const { a -= T(b); }
  };

  template <typename Src>
  struct LambdaBinaryMultiplication {
    void operator()(T& a, Src b) const { a *= T(b); }
  };

  template <typename Src>
  struct LambdaBinaryDivision {
    void operator()(T& a, Src b) const { a /= T(b); }
  };

  /// Accumulate in place
  template <typename Src>
  TensorView<T>& operator+=(TensorView<Src> const& tensor) {
    LambdaBinaryAddition<Src> op;
    elementwise_in_place(op, tensor);

    return *this;
  }

  /// Subtract in place
  template <typename Src>
  TensorView<T>& operator-=(TensorView<Src> const& tensor) {
    LambdaBinarySubtraction<Src> op;
    elementwise_in_place(op, tensor);

    return *this;
  }

  /// Multiply in place
  template <typename Src>
  TensorView<T>& operator*=(TensorView<Src> const& tensor) {
    LambdaBinaryMultiplication<Src> op;
    elementwise_in_place(op, tensor);

    return *this;
  }

  /// Divide in place
  template <typename Src>
  TensorView<T>& operator/=(TensorView<Src> const& tensor) {
    LambdaBinaryDivision<Src> op;
    elementwise_in_place(op, tensor);

    return *this;
  }

  /// Comparison operator
  struct EqualsOperator {
    bool equal;
    T eps;

    EqualsOperator(T _epsilon) : equal(true), eps(_epsilon) {}

    void operator()(T a, T b) {
      if (std::abs(T(a - b)) > eps * std::max(std::abs(a), std::abs(b))) {
        equal = false;
      }
    }
  };

  /// equality with epsilon tolerance
  bool equals(TensorView<T> const& tensor, T epsilon) const {
    EqualsOperator comparison_op(epsilon);
    bool equal_size = elementwise_in_place(comparison_op, tensor);

    return equal_size && comparison_op.equal;
  }

  /// Compares two values which are smaller or equal to a long long int
  struct BitEqualsOperator {
    bool equal;
    long long eps;
    uint64_t index;

    BitEqualsOperator(long long _ulps_threshold) : equal(true), eps(_ulps_threshold), index(0) {}

    void operator()(T a, T b) {
      // convert bits to integers
      long long bits_a = 0;
      long long bits_b = 0;

      *reinterpret_cast<T*>(&bits_a) = TypeTraits<T>::remove_negative_zero(a);
      *reinterpret_cast<T*>(&bits_b) = TypeTraits<T>::remove_negative_zero(b);

      // compute diff
      long long ulps = bits_a - bits_b;
      if (std::abs(ulps) > eps) {
        equal = false;
      }
      index++;
    }
  };

  /// equality with ulps tolerance
  bool bit_equals(TensorView<T> const& tensor, long long ulps_threshold = 0) {
    BitEqualsOperator comparison_op(ulps_threshold);
    bool equal_size = elementwise_in_place(comparison_op, tensor);

    return equal_size && comparison_op.equal;
  }

  /// Gets naked pointer to data
  T* data() const { return TensorView_t::data(); }

  /// Computes general matrix product among select dimensions of a tensor
  /// Assumes:
  ///   D: number of independent GEMMs to compute
  ///   H: height of matrix
  ///   W: width of matrix
  ///   C: "channels" of each element
  template <typename A, typename B, typename Ctype, typename Stype>
  void gemm(TensorView<A> const& tensor_a, TensorView<B> const& tensor_b, Stype alpha, Stype beta) {
    int const Batch = size(Dim_D);
    int const M = size(Dim_H);
    int const N = size(Dim_W);
    int const K = tensor_a.size(Dim_W);
    int const C = tensor_a.size(Dim_C);

    // Sizes must match
    if (tensor_a.size(Dim_H) != M || tensor_b.size(Dim_W) != N || tensor_b.size(Dim_C) != C ||
        tensor_b.size(Dim_H) != K) {
      return;
    }

    int const Mblock = 32;
    int const Nblock = 32;

    for (int batch = 0; batch < Batch; ++batch) {
      for (int row_block = 0; row_block < M; row_block += Mblock) {
        for (int col_block = 0; col_block < N; col_block += Nblock) {
          Ctype accum[Mblock][Nblock];

          for (int j = 0; j < Nblock; j++) {
            for (int i = 0; i < Mblock; i++) {
              accum[i][j] = Ctype(0);
            }
          }

          for (int k_block = 0; k_block < K; ++k_block) {
            for (int j = 0; j < Nblock; j++) {
              for (int i = 0; i < Mblock; i++) {
                int row = row_block + i;
                int col = col_block + j;

                if (row < M && col < N) {
                  for (int channel = 0; channel < C; ++channel) {
                    Ctype a(tensor_a.at(make_Coord(batch, row, k_block, channel)));
                    Ctype b(tensor_b.at(make_Coord(batch, k_block, col, channel)));

                    accum[i][j] += a * b;
                  }
                }
              }
            }
          }

          for (int j = 0; j < Nblock; j++) {
            for (int i = 0; i < Mblock; i++) {
              int row = row_block + i;
              int col = col_block + j;

              Coord_t coord = make_Coord(batch, row, col, 0);
              if (row < M && col < N) {
                at(coord) =
                    Cast<Stype, T>::apply(alpha * Stype(accum[i][j]) + beta * Stype(at(coord)));
              }
            }
          }
        }
      }
    }
  }

  /// Fills with random data
  template <typename Gen>
  void fill_random(Gen generator) {
    elementwise_stream(generator);
  }

  /// Procedurally assigns elements
  template <typename Gen>
  void generate(Gen generator) {
    elementwise_generate(generator);
  }

  /// Procedurally visits elements
  template <typename Gen>
  void visit(Gen& generator) const {
    elementwise_visit(generator);
  }

  /// Generator to fill a tensor with the identity matrix
  struct LambdaFillIdentity {
    T operator()(Coord_t const& coord) { return (coord.at(1) == coord.at(2) ? T(1) : T(0)); }
  };

  /// initializes with identity
  void fill_identity() {
    LambdaFillIdentity op;
    elementwise_generate(op);
  }

  /// Lambda for fill_linear()
  struct LambdaFillLinear {
    Coord_t v_;
    T offset_;

    LambdaFillLinear(Coord_t const& _v, T _offset) : v_(_v), offset_(_offset) {}

    T operator()(Coord_t const& coord) { return T(v_.template dot<int>(coord)) + offset_; }
  };

  /// computes elements as a linear combination of their coordinates
  void fill_linear(Coord_t v, T offset = T(0)) {
    LambdaFillLinear lambda(v, offset);
    elementwise_generate(lambda);
  }

  /// computes elements as a linear combination of their coordinates
  void fill_sequential(T v = T(1), T offset = T(0)) {
    int const count = size().count();
    for (int i = 0; i < count; ++i) {
      data()[i] = T(i);
    }
  }

  /// Returns a constant value
  struct LambdaFillValue {
    T value;

    LambdaFillValue(T _value) : value(_value) {}

    T operator()() { return value; }
  };

  /// fills with a value
  void fill(T val = T(0)) {
    LambdaFillValue op(val);
    elementwise_stream(op);
  }

  /// Conversion from Src to T
  template <typename Src>
  struct LambdaAssign {
    void operator()(T& a, Src b) const { a = T(b); }
  };

  /// copies from external data source and performs type conversion
  template <typename Src>
  void fill(TensorView<Src> const& tensor) {
    LambdaAssign<Src> op;
    elementwise_in_place(op, tensor);
  }

  /// Computes a norm
  struct LambdaNorm {
    double sum;

    LambdaNorm() : sum(0) {}

    void operator()(T const& element) {
      double value(element);
      double conj(element);  // TODO - conjugates for complex

      sum += value * conj;
    }
  };

  /// Computes the norm of the matrix in double-precision
  double norm() const {
    LambdaNorm op;
    elementwise_in_place(op);

    return std::sqrt(op.sum);
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass
