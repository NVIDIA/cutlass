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
/* \file
   \brief Execution environment
*/

#include <cstring>

#include "cutlass/numeric_types.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/tensor.h"

#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "cutlass/util/reference/host/tensor_fill.h"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/tensor_view_io.h"

#include "device_allocation.h"

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

size_t DeviceAllocation::bytes(library::NumericTypeID type, size_t capacity) {
  return size_t(cutlass::library::sizeof_bits(type)) * capacity / 8;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Layout>
static std::vector<int> get_packed_layout_stride(std::vector<int> const &extent) {

  typename Layout::TensorCoord extent_coord;
  typename Layout::Stride stride_coord;

  if (extent.size() != size_t(Layout::kRank)) {
    throw std::runtime_error("Layout does not have same rank as extent vector.");
  }

  for (int i = 0; i < Layout::kRank; ++i) {
    extent_coord[i] = extent.at(i);
  }

  std::vector<int> stride;
  stride.resize(Layout::kStrideRank, 0);

  Layout layout = Layout::packed(extent_coord);
  stride_coord = layout.stride();

  for (int i = 0; i < Layout::kStrideRank; ++i) {
    stride.at(i) = stride_coord[i];
  }

  return stride;
}

/// Returns the stride of a packed layout
std::vector<int> DeviceAllocation::get_packed_layout(
  library::LayoutTypeID layout_id, 
  std::vector<int> const &extent) {

  std::vector<int> stride;

  switch (layout_id) {
    case library::LayoutTypeID::kColumnMajor: 
      stride = get_packed_layout_stride<cutlass::layout::ColumnMajor>(extent);
      break;
    case library::LayoutTypeID::kRowMajor: 
      stride = get_packed_layout_stride<cutlass::layout::RowMajor>(extent);
      break;
    case library::LayoutTypeID::kColumnMajorInterleavedK4:
      stride = get_packed_layout_stride<cutlass::layout::ColumnMajorInterleaved<4>>(extent);
      break;
    case library::LayoutTypeID::kRowMajorInterleavedK4:
      stride = get_packed_layout_stride<cutlass::layout::RowMajorInterleaved<4>>(extent);
      break;
    case library::LayoutTypeID::kColumnMajorInterleavedK16:
      stride = get_packed_layout_stride<cutlass::layout::ColumnMajorInterleaved<16>>(extent);
      break;
    case library::LayoutTypeID::kRowMajorInterleavedK16:
      stride = get_packed_layout_stride<cutlass::layout::RowMajorInterleaved<16>>(extent);
      break;
    case library::LayoutTypeID::kTensorNCHW:
      stride = get_packed_layout_stride<cutlass::layout::TensorNCHW>(extent);
      break;
    case library::LayoutTypeID::kTensorNHWC:
      stride = get_packed_layout_stride<cutlass::layout::TensorNHWC>(extent);
      break;


    default: break;
  }

  return stride;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Template to use CUTLASS Layout functions to 
template <typename Layout>
static size_t construct_layout_(
  void *bytes,
  library::LayoutTypeID layout_id,
  std::vector<int> const &extent,
  std::vector<int> &stride) {

  if (extent.size() != Layout::kRank) {
    throw std::runtime_error(
      "Layout must have same rank as extent vector.");
  }

  if (Layout::kStrideRank && stride.empty()) {

    stride = get_packed_layout_stride<Layout>(extent);

    return construct_layout_<Layout>(
      bytes, 
      layout_id, 
      extent,
      stride);
  }
  else if (Layout::kStrideRank && stride.size() != Layout::kStrideRank) {
    throw std::runtime_error(
      "Layout requires either empty stride or stride vector matching Layout::kStrideRank");
  }

  typename Layout::Stride stride_coord;
  for (int i = 0; i < Layout::kStrideRank; ++i) {
    stride_coord[i] = stride.at(i);
  }

  typename Layout::TensorCoord extent_coord;
  for (int i = 0; i < Layout::kRank; ++i) {
    extent_coord[i] = extent.at(i);
  }

  // Construct the CUTLASS layout object from the stride object
  Layout layout(stride_coord);

  // Pack it into bytes
  if (bytes) {
    *reinterpret_cast<Layout *>(bytes) = layout; 
  }

  // Return capacity
  size_t capacity_ = layout.capacity(extent_coord);

  return capacity_;
}

/// returns the capacity needed
size_t DeviceAllocation::construct_layout(
  void *bytes,
  library::LayoutTypeID layout_id,
  std::vector<int> const &extent,
  std::vector<int> &stride) {

  switch (layout_id) {
    case library::LayoutTypeID::kColumnMajor: 
      return construct_layout_<cutlass::layout::ColumnMajor>(bytes, layout_id, extent, stride);
      
    case library::LayoutTypeID::kRowMajor: 
      return construct_layout_<cutlass::layout::RowMajor>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kColumnMajorInterleavedK4:
      return construct_layout_<cutlass::layout::ColumnMajorInterleaved<4>>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kRowMajorInterleavedK4:
      return construct_layout_<cutlass::layout::RowMajorInterleaved<4>>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kColumnMajorInterleavedK16:
      return construct_layout_<cutlass::layout::ColumnMajorInterleaved<16>>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kRowMajorInterleavedK16:
      return construct_layout_<cutlass::layout::RowMajorInterleaved<16>>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kTensorNCHW:
      return construct_layout_<cutlass::layout::TensorNHWC>(bytes, layout_id, extent, stride);

    case library::LayoutTypeID::kTensorNHWC:
      return construct_layout_<cutlass::layout::TensorNHWC>(bytes, layout_id, extent, stride);

    default: break;
  }

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

DeviceAllocation::DeviceAllocation(): 
  type_(library::NumericTypeID::kInvalid), 
  capacity_(0), 
  pointer_(nullptr),
  layout_(library::LayoutTypeID::kUnknown) {

}

DeviceAllocation::DeviceAllocation(
  library::NumericTypeID type, 
  size_t capacity
):
  type_(type), capacity_(capacity), pointer_(nullptr), layout_(library::LayoutTypeID::kUnknown) {

  cudaError_t result = cudaMalloc((void **)&pointer_, bytes(type, capacity));

  if (result != cudaSuccess) {
    type_ = library::NumericTypeID::kInvalid;
    capacity_ = 0;
    pointer_ = nullptr;
    throw std::bad_alloc();
  }
}

DeviceAllocation::DeviceAllocation(
  library::NumericTypeID type, 
  library::LayoutTypeID layout_id, 
  std::vector<int> const &extent, 
  std::vector<int> const &stride
):
  type_(type), capacity_(size_t(0)), pointer_(nullptr) {

  reset(type, layout_id, extent, stride);
}

DeviceAllocation::~DeviceAllocation() {
  if (pointer_) {
    cudaFree(pointer_);
  }
}

DeviceAllocation &DeviceAllocation::reset() {
  if (pointer_) {
    cudaFree(pointer_);
  }

  type_ = library::NumericTypeID::kInvalid;
  capacity_ = 0;
  pointer_ = nullptr;
  layout_ = library::LayoutTypeID::kUnknown;
  stride_.clear();
  extent_.clear();
  tensor_ref_buffer_.clear();

  return *this;
}

DeviceAllocation &DeviceAllocation::reset(library::NumericTypeID type, size_t capacity) {

  reset();

  cudaError_t result = cudaMalloc((void **)&pointer_, bytes(type, capacity));
  if (result != cudaSuccess) {
    throw std::bad_alloc();
  }

  type_ = type;
  capacity_ = capacity;
  layout_ = library::LayoutTypeID::kUnknown;
  stride_.clear();
  extent_.clear();

  tensor_ref_buffer_.resize(sizeof(pointer_), 0);
  std::memcpy(tensor_ref_buffer_.data(), &pointer_, sizeof(pointer_));

  return *this;
}

/// Allocates memory for a given layout and tensor
DeviceAllocation &DeviceAllocation::reset(
  library::NumericTypeID type, 
  library::LayoutTypeID layout_id, 
  std::vector<int> const &extent, 
  std::vector<int> const &stride) {

  reset();

  tensor_ref_buffer_.resize(sizeof(pointer_) + (sizeof(int) * library::get_layout_stride_rank(layout_id)), 0);

  type_ = type;

  layout_ = layout_id;
  stride_ = stride;
  extent_ = extent;

  capacity_ = construct_layout(
    tensor_ref_buffer_.data() + sizeof(pointer_), 
    layout_id, 
    extent, 
    stride_);

  cudaError_t result = cudaMalloc((void **)&pointer_, bytes(type, capacity_));
  if (result != cudaSuccess) {
    throw std::bad_alloc();
  }

  std::memcpy(tensor_ref_buffer_.data(), &pointer_, sizeof(pointer_));

  return *this;
}

bool DeviceAllocation::good() const {
  return (capacity_ && pointer_);
}

library::NumericTypeID DeviceAllocation::type() const {
  return type_;
}

void *DeviceAllocation::data() const {
  return pointer_;
}

library::LayoutTypeID DeviceAllocation::layout() const {
  return layout_;
}

std::vector<int> const & DeviceAllocation::stride() const {
  return stride_;
}

/// Gets the extent vector
std::vector<int> const & DeviceAllocation::extent() const {
  return extent_;
}

size_t DeviceAllocation::capacity() const {
  return capacity_;
}

size_t DeviceAllocation::bytes() const {
  return bytes(type_, capacity_);
}

/// Copies from an equivalent-sized tensor in device memory
void DeviceAllocation::copy_from_device(void const *ptr) {
  cudaError_t result = cudaMemcpy(data(), ptr, bytes(), cudaMemcpyDeviceToDevice);
  if (result != cudaSuccess) {
    throw std::runtime_error("Failed device-to-device copy");
  }
}

/// Copies from an equivalent-sized tensor in device memory
void DeviceAllocation::copy_from_host(void const *ptr) {
  cudaError_t result = cudaMemcpy(data(), ptr, bytes(), cudaMemcpyHostToDevice);
  if (result != cudaSuccess) {
    throw std::runtime_error("Failed device-to-device copy");
  }
}

/// Copies from an equivalent-sized tensor in device memory
void DeviceAllocation::copy_to_host(void *ptr) {
  cudaError_t result = cudaMemcpy(ptr, data(), bytes(), cudaMemcpyDeviceToHost);
  if (result != cudaSuccess) {
    throw std::runtime_error("Failed device-to-device copy");
  }
}

void DeviceAllocation::initialize_random_device(int seed, Distribution dist) {
  if (!good()) {
    throw std::runtime_error("Attempting to initialize invalid allocation.");
  }

  // Instantiate calls to CURAND here. This file takes a long time to compile for
  // this reason.

  switch (type_) {
  case library::NumericTypeID::kF16:
    cutlass::reference::device::BlockFillRandom<cutlass::half_t>(
      reinterpret_cast<cutlass::half_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kF32:
    cutlass::reference::device::BlockFillRandom<float>(
      reinterpret_cast<float *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kF64:
    cutlass::reference::device::BlockFillRandom<double>(
      reinterpret_cast<double *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS8:
    cutlass::reference::device::BlockFillRandom<int8_t>(
      reinterpret_cast<int8_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS16:
    cutlass::reference::device::BlockFillRandom<int16_t>(
      reinterpret_cast<int16_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS32:
    cutlass::reference::device::BlockFillRandom<int32_t>(
      reinterpret_cast<int32_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS64:
    cutlass::reference::device::BlockFillRandom<int64_t>(
      reinterpret_cast<int64_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU8:
    cutlass::reference::device::BlockFillRandom<uint8_t>(
      reinterpret_cast<uint8_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU16:
    cutlass::reference::device::BlockFillRandom<uint16_t>(
      reinterpret_cast<uint16_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU32:
    cutlass::reference::device::BlockFillRandom<uint32_t>(
      reinterpret_cast<uint32_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU64:
    cutlass::reference::device::BlockFillRandom<uint64_t>(
      reinterpret_cast<uint64_t *>(pointer_),
      capacity_,
      seed,
      dist
    );
    break;
  default: break;
  }
}


void DeviceAllocation::initialize_random_host(int seed, Distribution dist) {
  if (!good()) {
    throw std::runtime_error("Attempting to initialize invalid allocation.");
  }

  std::vector<uint8_t> host_data(bytes());

  switch (type_) {
  case library::NumericTypeID::kF16:
    cutlass::reference::host::BlockFillRandom<cutlass::half_t>(
      reinterpret_cast<cutlass::half_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kF32:
    cutlass::reference::host::BlockFillRandom<float>(
      reinterpret_cast<float *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kF64:
    cutlass::reference::host::BlockFillRandom<double>(
      reinterpret_cast<double *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS8:
    cutlass::reference::host::BlockFillRandom<int8_t>(
      reinterpret_cast<int8_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS16:
    cutlass::reference::host::BlockFillRandom<int16_t>(
      reinterpret_cast<int16_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS32:
    cutlass::reference::host::BlockFillRandom<int32_t>(
      reinterpret_cast<int32_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kS64:
    cutlass::reference::host::BlockFillRandom<int64_t>(
      reinterpret_cast<int64_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU8:
    cutlass::reference::host::BlockFillRandom<uint8_t>(
      reinterpret_cast<uint8_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU16:
    cutlass::reference::host::BlockFillRandom<uint16_t>(
      reinterpret_cast<uint16_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU32:
    cutlass::reference::host::BlockFillRandom<uint32_t>(
      reinterpret_cast<uint32_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  case library::NumericTypeID::kU64:
    cutlass::reference::host::BlockFillRandom<uint64_t>(
      reinterpret_cast<uint64_t *>(host_data.data()),
      capacity_,
      seed,
      dist
    );
    break;
  default: break;
  }

  copy_from_host(host_data.data());
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Returns true if two blocks have exactly the same value
bool DeviceAllocation::block_compare_equal(
  library::NumericTypeID numeric_type, 
  void const *ptr_A, 
  void const *ptr_B, 
  size_t capacity) {

  switch (numeric_type) {
  case library::NumericTypeID::kF16:
    return reference::device::BlockCompareEqual<half_t>(
      reinterpret_cast<half_t const *>(ptr_A), 
      reinterpret_cast<half_t const *>(ptr_B), 
      capacity);
    
  case library::NumericTypeID::kF32:
    return reference::device::BlockCompareEqual<float>(
      reinterpret_cast<float const *>(ptr_A), 
      reinterpret_cast<float const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kF64:
    return reference::device::BlockCompareEqual<double>(
      reinterpret_cast<double const *>(ptr_A), 
      reinterpret_cast<double const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kS8:
    return reference::device::BlockCompareEqual<int8_t>(
      reinterpret_cast<int8_t const *>(ptr_A), 
      reinterpret_cast<int8_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kS16:
    return reference::device::BlockCompareEqual<int16_t>(
      reinterpret_cast<int16_t const *>(ptr_A), 
      reinterpret_cast<int16_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kS32:
    return reference::device::BlockCompareEqual<int32_t>(
      reinterpret_cast<int32_t const *>(ptr_A), 
      reinterpret_cast<int32_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kS64:
    return reference::device::BlockCompareEqual<int64_t>(
      reinterpret_cast<int64_t const *>(ptr_A), 
      reinterpret_cast<int64_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kU8:
    return reference::device::BlockCompareEqual<uint8_t>(
      reinterpret_cast<uint8_t const *>(ptr_A), 
      reinterpret_cast<uint8_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kU16:
    return reference::device::BlockCompareEqual<uint16_t>(
      reinterpret_cast<uint16_t const *>(ptr_A), 
      reinterpret_cast<uint16_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kU32:
    return reference::device::BlockCompareEqual<uint32_t>(
      reinterpret_cast<uint32_t const *>(ptr_A), 
      reinterpret_cast<uint32_t const *>(ptr_B), 
      capacity);

  case library::NumericTypeID::kU64:
    return reference::device::BlockCompareEqual<uint64_t>(
      reinterpret_cast<uint64_t const *>(ptr_A), 
      reinterpret_cast<uint64_t const *>(ptr_B), 
      capacity);

  default:
    throw std::runtime_error("Unsupported numeric type");
  }
}

/// Returns true if two blocks have approximately the same value
bool DeviceAllocation::block_compare_relatively_equal(
  library::NumericTypeID numeric_type, 
  void const *ptr_A, 
  void const *ptr_B, 
  size_t capacity,
  double epsilon,
  double nonzero_floor) {

  switch (numeric_type) {
  case library::NumericTypeID::kF16:
    return reference::device::BlockCompareRelativelyEqual<half_t>(
      reinterpret_cast<half_t const *>(ptr_A), 
      reinterpret_cast<half_t const *>(ptr_B),
      capacity, 
      static_cast<half_t>(epsilon), 
      static_cast<half_t>(nonzero_floor));
    
  case library::NumericTypeID::kF32:
    return reference::device::BlockCompareRelativelyEqual<float>(
      reinterpret_cast<float const *>(ptr_A), 
      reinterpret_cast<float const *>(ptr_B),
      capacity, 
      static_cast<float>(epsilon), 
      static_cast<float>(nonzero_floor));

  case library::NumericTypeID::kF64:
    return reference::device::BlockCompareRelativelyEqual<double>(
      reinterpret_cast<double const *>(ptr_A), 
      reinterpret_cast<double const *>(ptr_B),
      capacity, 
      static_cast<double>(epsilon), 
      static_cast<double>(nonzero_floor));

  case library::NumericTypeID::kS8:
    return reference::device::BlockCompareRelativelyEqual<int8_t>(
      reinterpret_cast<int8_t const *>(ptr_A), 
      reinterpret_cast<int8_t const *>(ptr_B),
      capacity, 
      static_cast<int8_t>(epsilon), 
      static_cast<int8_t>(nonzero_floor));

  case library::NumericTypeID::kS16:
    return reference::device::BlockCompareRelativelyEqual<int16_t>(
      reinterpret_cast<int16_t const *>(ptr_A), 
      reinterpret_cast<int16_t const *>(ptr_B),
      capacity, 
      static_cast<int16_t>(epsilon), 
      static_cast<int16_t>(nonzero_floor));

  case library::NumericTypeID::kS32:
    return reference::device::BlockCompareRelativelyEqual<int32_t>(
      reinterpret_cast<int32_t const *>(ptr_A), 
      reinterpret_cast<int32_t const *>(ptr_B),
      capacity, 
      static_cast<int32_t>(epsilon), 
      static_cast<int32_t>(nonzero_floor));

  case library::NumericTypeID::kS64:
    return reference::device::BlockCompareRelativelyEqual<int64_t>(
      reinterpret_cast<int64_t const *>(ptr_A), 
      reinterpret_cast<int64_t const *>(ptr_B),
      capacity, 
      static_cast<int64_t>(epsilon), 
      static_cast<int64_t>(nonzero_floor));

  case library::NumericTypeID::kU8:
    return reference::device::BlockCompareRelativelyEqual<uint8_t>(
      reinterpret_cast<uint8_t const *>(ptr_A), 
      reinterpret_cast<uint8_t const *>(ptr_B),
      capacity, 
      static_cast<uint8_t>(epsilon), 
      static_cast<uint8_t>(nonzero_floor));

  case library::NumericTypeID::kU16:
    return reference::device::BlockCompareRelativelyEqual<uint16_t>(
      reinterpret_cast<uint16_t const *>(ptr_A), 
      reinterpret_cast<uint16_t const *>(ptr_B),
      capacity, 
      static_cast<uint16_t>(epsilon), 
      static_cast<uint16_t>(nonzero_floor));

  case library::NumericTypeID::kU32:
    return reference::device::BlockCompareRelativelyEqual<uint32_t>(
      reinterpret_cast<uint32_t const *>(ptr_A), 
      reinterpret_cast<uint32_t const *>(ptr_B),
      capacity, 
      static_cast<uint32_t>(epsilon), 
      static_cast<uint32_t>(nonzero_floor));

  case library::NumericTypeID::kU64:
    return reference::device::BlockCompareRelativelyEqual<uint64_t>(
      reinterpret_cast<uint64_t const *>(ptr_A), 
      reinterpret_cast<uint64_t const *>(ptr_B),
      capacity, 
      static_cast<uint64_t>(epsilon), 
      static_cast<uint64_t>(nonzero_floor));

  default:
    throw std::runtime_error("Unsupported numeric type");
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Permits copying dynamic vectors into static-length vectors 
template <typename TensorCoord, int Rank>
struct vector_to_coord {
  
  vector_to_coord(TensorCoord &coord, std::vector<int> const &vec) {

    coord[Rank - 1] = vec.at(Rank - 1);
    
    if (Rank > 1) {
      vector_to_coord<TensorCoord, Rank - 1>(coord, vec);
    }
  }
};

/// Permits copying dynamic vectors into static-length vectors 
template <typename TensorCoord>
struct vector_to_coord<TensorCoord, 1> {
  
  vector_to_coord(TensorCoord &coord, std::vector<int> const &vec) {

    coord[0] = vec.at(0);
  }
};

/// Permits copying dynamic vectors into static-length vectors 
template <typename TensorCoord>
struct vector_to_coord<TensorCoord, 0> {
  
  vector_to_coord(TensorCoord &coord, std::vector<int> const &vec) {

  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Element, typename Layout>
static void write_tensor_csv_static_tensor_view(
  std::ostream &out, 
  DeviceAllocation &allocation) {

  Coord<Layout::kRank> extent;
  Coord<Layout::kStrideRank> stride;

  if (allocation.extent().size() != Layout::kRank) {
    throw std::runtime_error("Allocation extent has invalid rank");
  }

  if (allocation.stride().size() != Layout::kStrideRank) {
    throw std::runtime_error("Allocation stride has invalid rank");
  }

  vector_to_coord<Coord<Layout::kRank>, Layout::kRank>(extent, allocation.extent());
  vector_to_coord<Coord<Layout::kStrideRank>, Layout::kStrideRank>(stride, allocation.stride());

  Layout layout(stride);
  HostTensor<Element, Layout> host_tensor(extent, layout, false);

  if (host_tensor.capacity() != allocation.capacity()) {
    throw std::runtime_error("Unexpected capacity to equal.");
  }

  host_tensor.copy_in_device_to_host(static_cast<Element const *>(allocation.data()), host_tensor.capacity());

  TensorViewWrite(out, host_tensor.host_view());
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T>
static void write_tensor_csv_static_type(
  std::ostream &out, 
  DeviceAllocation &allocation) {

  switch (allocation.layout()) {
    case library::LayoutTypeID::kRowMajor:
      write_tensor_csv_static_tensor_view<T, layout::RowMajor>(out, allocation);
      break;
    case library::LayoutTypeID::kColumnMajor:
      write_tensor_csv_static_tensor_view<T, layout::ColumnMajor>(out, allocation);
      break;
    case library::LayoutTypeID::kTensorNHWC:
      write_tensor_csv_static_tensor_view<T, layout::TensorNHWC>(out, allocation);
      break;
    default:
      throw std::runtime_error("Unhandled layout");
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Writes a tensor to csv 
void DeviceAllocation::write_tensor_csv(
  std::ostream &out) {

  switch (this->type()) {
  case library::NumericTypeID::kF16:
    write_tensor_csv_static_type<half_t>(out, *this);
    break;
    
  case library::NumericTypeID::kF32:
    write_tensor_csv_static_type<float>(out, *this);
    break;

  case library::NumericTypeID::kF64:
    write_tensor_csv_static_type<double>(out, *this);
    break;

  case library::NumericTypeID::kS8:
    write_tensor_csv_static_type<int8_t>(out, *this);
    break;

  case library::NumericTypeID::kS16:
    write_tensor_csv_static_type<int16_t>(out, *this);
    break;

  case library::NumericTypeID::kS32:
    write_tensor_csv_static_type<int32_t>(out, *this);
    break;

  case library::NumericTypeID::kS64:
    write_tensor_csv_static_type<int64_t>(out, *this);
    break;

  case library::NumericTypeID::kU8:
    write_tensor_csv_static_type<uint8_t>(out, *this);
    break;

  case library::NumericTypeID::kU16:
    write_tensor_csv_static_type<uint16_t>(out, *this);
    break;

  case library::NumericTypeID::kU32:
    write_tensor_csv_static_type<uint32_t>(out, *this);
    break;

  case library::NumericTypeID::kU64:
    write_tensor_csv_static_type<uint64_t>(out, *this);
    break;

  default:
    throw std::runtime_error("Unsupported numeric type");
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass
