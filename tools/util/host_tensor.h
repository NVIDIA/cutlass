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
#pragma once

/*! \file
    \brief Template class to perform computations on tensors and manage memory.
*/

#include <cutlass/cutlass.h>
#include <cutlass/matrix_traits.h>
#include <tools/util/device_memory.h>
#include <tools/util/host_tensor_view.h>
#include <tools/util/type_traits.h>
#include <vector>

namespace cutlass {

template <typename T, bool DeviceBacked_ = true>
class HostTensor : public HostTensorView<T> {
 public:
  /// Type used for device-side allocations
  typedef typename TypeTraits<T>::device_type DeviceType;

  /// Base class
  typedef HostTensorView<T> Base;

  /// If true, allocates device side memory
  static bool const DeviceBacked = DeviceBacked_;

  /// Rank of tensor
  static int const Rank = Base::Rank;

  /// Type used to compute the offset of an element to the base of a tensor
  typedef typename Base::Offset_t Offset_t;

  /// Tensor reference to host memory
  typedef typename Base::TensorRef_t TensorRef_t;

  /// Tensor reference to device memory
  typedef TensorRef<DeviceType, TensorRef_t::Rank> DeviceTensorRef;

  /// Tensor reference to constant device memory
  typedef TensorRef<DeviceType const, TensorRef_t::Rank> ConstDeviceTensorRef;

  /// Coordinate into tensor
  typedef typename Base::Coord_t Coord_t;

 private:
  /// Host-side memory allocation
  std::vector<T> host_;

  /// Device-side memory
  cutlass::device_memory::allocation<DeviceType> device_;

 public:
  //
  // Device and Host Methods
  //

  /// Default constructor
  HostTensor() {}

  /// Constructs a Tensor_view from stride and size
  HostTensor(Coord_t const& _stride, Coord_t const& _size) { reset(_stride, _size); }

  /// Constructs a HostTensor from size - infers strides
  HostTensor(Coord_t const& _size) {
    Coord_t _stride = make_Coord(
        _size.at(2) * _size.at(1) * _size.at(0), _size.at(1) * _size.at(0), _size.at(0), 1);
    reset(_stride, _size);
  }

  /// Returns the number of elements needed to back vector
  size_t capacity() { return Base::capacity(); }

  /// Returns true if the Tensor_view is bound to some memory
  bool good() const { return Base::good(); }

  /// Updates the reference and size of a Tensor_view object
  void reset(Coord_t const& _stride, Coord_t const& _size) {
    size_t _capacity = _size.at(0) * _stride.at(0);

    DeviceType* _device_memory = nullptr;
    if (DeviceBacked) {
      _device_memory = cutlass::device_memory::allocate<DeviceType>(_capacity);
    }

    host_.clear();
    host_.resize(_capacity);
    device_.reset(_device_memory, _capacity);

    Base::reset(TensorRef_t(host_.data(), _stride), _size);
  }

  /// Initializes the host tensor as a matrix
  void resize_matrix(int rows, int columns, MatrixLayout::Kind layout) {
    bool col_major = (layout == MatrixLayout::kColumnMajor);
    int ldm = (col_major ? rows : columns);

    Coord_t stride = make_Coord(rows * columns, col_major ? 1 : ldm, col_major ? ldm : 1, 1);

    Coord_t size = make_Coord(1, rows, columns, 1);

    reset(stride, size);
  }

  /// Simplifies resizing the host tensor
  void resize(int elements) { resize_matrix(1, elements, MatrixLayout::kColumnMajor); }

  /// Gets pointer to host data
  T const* host_data() const { return &host_[0]; }

  /// Gets pointer to host data
  T* host_data() { return &host_[0]; }

  /// Gets pointer to device data
  DeviceType* device_data() const { return device_.get(); }

  /// Copies data from device to host
  void sync_host() {
    if (DeviceBacked) {
      device_memory::copy_to_host(
          host_.data(), reinterpret_cast<T const*>(device_.get()), host_.size());
    }
  }

  /// Copies data from host to device
  void sync_device() {
    if (DeviceBacked) {
      device_memory::copy_to_device(
          device_.get(), reinterpret_cast<DeviceType const*>(host_.data()), host_.size());
    }
  }

  /// Copy data from a caller-supplied device pointer
  void copy_to_host(DeviceType const *ptr_device) {
    device_memory::copy_to_host(
      host_.data(), reinterpret_cast<T const *>(ptr_device), host_.size());
  }

  /// Copies data to a caller-supplied device pointer
  void copy_to_device(DeviceType *ptr_device) {
    device_memory::copy_to_device(
      ptr_device, reinterpret_cast<DeviceType const *>(host_.data()), host_.size());
  }

  /// Accesses the tensor reference pointing to data
  TensorRef_t& host_ref() { return Base::ref(); }

  /// Accesses the tensor reference pointing to data
  TensorRef_t const& host_ref() const { return Base::ref(); }

  /// Accesses the tensor reference pointing to data
  DeviceTensorRef device_ref() const { return DeviceTensorRef(device_data(), stride()); }

  /// Returns a tensor ref to constant memory on the device
  ConstDeviceTensorRef const_device_ref() const {
    return ConstDeviceTensorRef(device_data(), stride());
  }

  /// Accesses the size
  Coord_t const& size() const { return Base::size(); }

  /// Accesses the size
  int size(int dim) const { return Base::size(dim); }

  /// Accesses the size
  Coord_t const& stride() const { return Base::stride(); }

  /// Accesses the size
  int stride(int dim) const { return Base::stride(dim); }

  /// Returns the index of an element
  Offset_t offset(Coord_t const& coord) const { return Base::offset(coord); }

  /// Determines whether a location is within a tensor
  bool contains(Coord_t const& coord) const { return Base::contains(coord); }

  /// Element-wise accessor
  T& at(Coord_t const& coord) const { return Base::at(coord); }

  /// Element-wise accessor
  T& operator[](Coord_t const& coord) { return at(coord); }

  /// Element-wise accessor with basic offset
  T& at(int idx) const { return Base::at(idx); }

  /// Returns a Tensor_view given location and size quantities
  TensorView<T> subview(Coord_t const& _location, Coord_t _size) const {
    return Base::subview(_location, _size);
  }

  /// Recurses through all dimensions and applies a unary operation
  template <typename F>
  void elementwise_in_place(F& op, int dim = 0, Offset_t dst_offset_base = 0) {
    Base::elementwise_in_place(op, dim, dst_offset_base);
  }

  /// Recurses through all dimensions and applies a unary operator, supplying the logical
  /// coordinate within the tensor as an argument
  template <typename F>
  void elementwise_stream(F& op, int dim = 0, Offset_t dst_offset_base = 0) {
    Base::elementwise_stream(op, dim, dst_offset_base);
  }

  /// Recurses through all dimensions and applies a unary operator, supplying the logical
  /// coordinate within the tensor as an argument
  template <typename F>
  void elementwise_generate(F& op,
                            int dim = 0,
                            Offset_t dst_offset_base = 0,
                            Coord_t coord = Coord_t(0)) {
    Base::elementwise_generate(op, dim, dst_offset_base, coord);
  }

  /// Recurses through all dimensions and applies a binary operation
  template <typename Src, typename F>
  bool elementwise_in_place(F& op,
                            int dim,
                            TensorView<Src> const& tensor,
                            Offset_t dst_offset_base = 0,
                            Offset_t src_offset_base = 0) {
    return Base::elementwise_in_place(op, dim, tensor, dst_offset_base, src_offset_base);
  }

  /// Accumulate in place
  template <typename Src>
  TensorView<T>& operator+=(TensorView<Src> const& tensor) {
    Base::operator+=(tensor);
    sync_device();
    return *this;
  }

  /// Subtract in place
  template <typename Src>
  TensorView<T>& operator-=(TensorView<Src> const& tensor) {
    Base::operator-=(tensor);
    sync_device();
    return *this;
  }

  /// Multiply in place
  template <typename Src>
  TensorView<T>& operator*=(TensorView<Src> const& tensor) {
    Base::operator*=(tensor);
    sync_device();
    return *this;
  }

  /// Divide in place
  template <typename Src>
  TensorView<T>& operator/=(TensorView<Src> const& tensor) {
    Base::operator/=(tensor);
    sync_device();
    return *this;
  }

  /// equality with epsilon tolerance
  bool equals(TensorView<T> const& tensor, T epsilon) const {
    return Base::equals(tensor, epsilon);
  }

  /// equality with ulps tolerance
  bool bit_equals(TensorView<T> const& tensor, long long ulps_threshold = 0) {
    return Base::bit_equals(tensor, ulps_threshold);
  }

  /// Computes general matrix product among select dimensions of a tensor
  /// Assumes:
  ///   D: number of independent GEMMs to compute
  ///   H: height of matrix
  ///   W: width of matrix
  template <
      /// Data type of A matrix elements
      typename A,
      /// Data type of B matrix elements
      typename B,
      /// Data type of "compute" type (i.e. accumulator)
      typename Ctype,
      /// Data type of scale factors
      typename Stype>
  void gemm(TensorView<A> const& tensor_a, TensorView<B> const& tensor_b, Stype alpha, Stype beta) {
    Base::template gemm<A, B, Ctype, Stype>(tensor_a, tensor_b, alpha, beta);
  }

  /// Fills with random data
  template <typename Gen>
  void fill_random(Gen generator) {
    Base::fill_random(generator);
    sync_device();
  }

  /// Procedurally assigns elements
  template <typename Gen>
  void generate(Gen generator) {
    Base::generate(generator);
    sync_device();
  }

  /// Procedurally visits elements
  template <typename Gen>
  void visit(Gen& generator) const {
    Base::visit(generator);
  }

  /// initializes with identity
  void fill_identity() {
    Base::fill_identity();
    sync_device();
  }

  /// computes elements as a linear combination of their coordinates
  void fill_linear(Coord_t v, T offset = T(0)) {
    Base::fill_linear(v, offset);
    sync_device();
  }

  /// computes elements as a linear combination of their coordinates
  void fill_sequential(T v = T(1), T offset = T(0)) {
    Base::fill_sequential(v, offset);
    sync_device();
  }

  /// fills with a value
  void fill(T val = T(0)) {
    Base::fill(val);
    sync_device();
  }

  /// Copies from external data source and performs type conversion
  template <typename Src>
  void fill(TensorView<Src> const& tensor) {
    Base::fill(tensor);
    sync_device();
  }

  /// Computes the norm of the matrix in double-precision
  double norm() const { return Base::norm(); }
};
}  // namespace cutlass
