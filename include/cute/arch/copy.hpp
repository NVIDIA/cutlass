#pragma once

#include <cute/config.hpp>

#include <cute/arch/util.hpp>
#include <cute/numeric/numeric_types.hpp>

namespace cute
{

//
// Direct Copy for any specific types
//

template <class S, class D = S>
struct UniversalCopy
{
  using SRegisters = S[1];
  using DRegisters = D[1];

  // Sanity
  static_assert(sizeof_bits_v<S> >= 8);
  static_assert(sizeof_bits_v<D> >= 8);

  CUTE_HOST_DEVICE static constexpr void
  copy(S const& src,
       D      & dst)
  {
    dst = src;
  }
};

//
// Placeholder for the copy algorithm's stronger auto-vectorizing behavior
//   that assumes alignment of pointers and dynamic layouts up to MaxVecBits
//

template <int MaxVecBits = 128>
struct AutoVectorizingCopyWithAssumedAlignment
     : UniversalCopy<uint_bit_t<MaxVecBits>>
{
  static_assert(MaxVecBits == 8 || MaxVecBits == 16 || MaxVecBits == 32 || MaxVecBits == 64 || MaxVecBits == 128,
                "Expected MaxVecBits to be 8 or 16 or 32 or 64 or 128 for alignment and performance.");
};

//
// AutoVectorizingCopy alias assumes maximal alignment of pointers and dynamic strides.
//   If this is not the case then AutoVectorizingCopyWithAssumedAlignment should be used instead
//

using AutoVectorizingCopy = AutoVectorizingCopyWithAssumedAlignment<128>;

//
// DefaultCopy alias does not assume alignment of pointers or dynamic strides.
//

using DefaultCopy = AutoVectorizingCopyWithAssumedAlignment<8>;

//
// Copy policy automatically selecting between
// UniversalCopy and cp.async , based on type and memory space.
//
struct AutoCopyAsync {};

//
// Global memory prefetch into L2
//

CUTE_HOST_DEVICE static void
prefetch(void const* gmem_ptr)
{
#if defined(__CUDA_ARCH__)
  asm volatile("prefetch.global.L2 [%0];\n" : : "l"(gmem_ptr) : "memory");
#endif
}

} // end namespace cute
