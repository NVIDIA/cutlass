#pragma once

//fwd declare OCL function and OCL types
#include <sycl.hpp> //for sycl::vec

#ifdef __SYCL_DEVICE_ONLY__ 
template<class T, int N> using vector_t = typename sycl::vec<T,N>::vector_t;
#else 
template<class T, int N> using vector_t = sycl::vec<T,N>;
#endif

using float8 = vector_t<float, 8>;
using short8 = vector_t<short, 8>;
using ushort8 = vector_t<ushort, 8>;
using int2_ = vector_t<int, 2>; //conflicts with vector_types
using int8 = vector_t<int, 8>;
using uint8 = vector_t<uint, 8>;
