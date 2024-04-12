
#pragma once

#include <cute/config.hpp>
#include <cute/arch/mma.hpp>
#include <cute/util/sycl_vec.hpp>

#ifdef __SYCL_DEVICE_ONLY__ 
#define SYCL_DEVICE_OCL(x) SYCL_EXTERNAL x
#else 
#define SYCL_DEVICE_OCL(x) inline x { assert(false); }
#endif

SYCL_DEVICE_OCL(float8 intel_sub_group_bf16_bf16_matrix_mad_k16(short8 a, int8 b, float8 acc));
SYCL_DEVICE_OCL(float  intel_sub_group_bf16_bf16_matrix_mad_k16(short  a, int8 b, float  acc));
#undef SYCL_DEVICE_OCL

namespace cute {
//MxNxK_A,B,C,D
//# of vector component of a x subgroup-size x function name
//float8 intel_sub_group_bf16_bf16_matrix_mad_k16(short8 a, int8 b, float8 acc);
//TODO: Is A really not transposed? Maybe better a macro than separate define for 1,2,4,8
struct XE_8x16x16_BF16BF16F32F32_NN
{
  using DRegisters = float8[1];
  using ARegisters = short8[1];
  using BRegisters = int8[1];
  using CRegisters = float8[1];

  CUTE_HOST_DEVICE static void
  fma(float8      & d,
      short8 const& a,
      int8   const& b,
      float8 const& c)
  {
    d = intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
  }
};
//float  intel_sub_group_bf16_bf16_matrix_mad_k16(short  a, int8 b, float  acc)
struct XE_1x16x16_BF16BF16F32F32_NN
{
  using DRegisters = float[1];
  using ARegisters = short[1];
  using BRegisters = int8[1];
  using CRegisters = float[1];

  CUTE_HOST_DEVICE static void
  fma(float      & d,
      short const& a,
      int8  const& b,
      float const& c)
  {
    d = intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
  }
};
} //namespace cute
