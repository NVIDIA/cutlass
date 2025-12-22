/*! \file
    \brief AlignedBuffer is a container for trivially copyable elements suitable for use in
      unions and shared memory.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"

namespace cutlass {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Modifies semantics of cutlass::Array<> to provide guaranteed alignment. 
template <
  typename T,
  int N,
  int Align = 16
>
struct AlignedBuffer {
  
  /// Internal storage type
  using Storage = uint8_t;

  /// Number of logical elements held in buffer
  static int const kCount = N;

  /// Alignment requirement in bytes
  static int const kAlign = Align;

  /// Number of storage elements
  static int const kBytes = 
    (sizeof_bits<T>::value * N + 7) / 8;

private:

  /// Internal storage
  alignas(Align) Storage storage[kBytes];

public:

  //
  // C++ standard members
  //

  typedef T value_type;
  typedef size_t size_type;
  typedef ptrdiff_t difference_type;
  typedef value_type *pointer;
  typedef value_type const * const_pointer;

  using Array = Array<T, N>;
  using reference = typename Array::reference;
  using const_reference = typename Array::const_reference;

public:

  CUTLASS_HOST_DEVICE
  pointer data() {
    return reinterpret_cast<pointer>(storage); 
  }

  CUTLASS_HOST_DEVICE
  const_pointer data() const {
    return reinterpret_cast<pointer>(storage); 
  }
  
  CUTLASS_HOST_DEVICE
  Storage * raw_data() {
    return storage;
  }

  CUTLASS_HOST_DEVICE
  Storage const * raw_data() const {
    return storage;
  }


  CUTLASS_HOST_DEVICE
  constexpr bool empty() const {
    return !kCount;
  }

  CUTLASS_HOST_DEVICE
  constexpr size_type size() const {
    return kCount;
  }

  CUTLASS_HOST_DEVICE
  constexpr size_type max_size() const {
    return kCount;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

