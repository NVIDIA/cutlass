#pragma once

#include <cute/arch/mma_xe.hpp>
#include <cute/atom/mma_traits.hpp>

#include <cute/layout.hpp>

namespace cute
{
template <>
struct MMA_Traits<XE_8x16x16_BF16BF16F32F32_NN>
{
  using ElementDVal = float;
  using ElementAVal = sycl::ext::oneapi::bfloat16;
  using ElementBVal = sycl::ext::oneapi::bfloat16;
  using ElementCVal = float;

  using Shape_MNK = Shape<_8,_16,_16>;
  using ThrID   = Layout<_16>;
  using ALayout = Layout<Shape<_8, _16>, Stride<_8, _1>>;  // (T16,V8) -> (m,n) 
  using BLayout = Layout<Shape<_16, _16>, Stride<_16, _1>>;
  using CLayout = Layout<Shape<_8, _16>, Stride<_8, _1>>;
};
}