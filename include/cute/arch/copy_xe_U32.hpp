/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once

#include <cute/util/sycl_vec.hpp>
#include "cute/config.hpp"

namespace cute
{
struct XE_2D_U32x1x16_LD_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 1, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x2x16_LD_N {
  using BlockShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 2, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x4x16_LD_N {
  using BlockShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 4, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x8x16_LD_N {
  using BlockShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 8, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x16x16_LD_N {
  using BlockShape = Shape<_16, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x32x16_LD_N {
  using BlockShape = Shape<_32, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 16, 32, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x1x8_LD_N {
  using BlockShape = Shape<_32, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 1, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x2x8_LD_N {
  using BlockShape = Shape<_2, _8>;
  using ValueShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 2, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x4x8_LD_N {
  using BlockShape = Shape<_4, _8>;
  using ValueShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 4, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x8x8_LD_N {
  using BlockShape = Shape<_8, _8>;
  using ValueShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 8, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x16x8_LD_N {
  using BlockShape = Shape<_16, _8>;
  using ValueShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x32x8_LD_N {
  using BlockShape = Shape<_32, _8>;
  using ValueShape = Shape<_16, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 32, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x1x16_LD_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 1, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x2x16_LD_N {
  using BlockShape = Shape<_2, _16>;
  using ValueShape = Shape<_1, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 2, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x4x16_LD_N {
  using BlockShape = Shape<_4, _16>;
  using ValueShape = Shape<_2, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 4, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x8x16_LD_N {
  using BlockShape = Shape<_8, _16>;
  using ValueShape = Shape<_4, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 8, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_TF32x16x16_LD_N {
  using BlockShape = Shape<_16, _16>;
  using ValueShape = Shape<_8, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 16, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }

  struct PREFETCH {
    CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                        int height, int pitch,
                                        intel::coord_t coord) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
   detail::XeSubgroup2DBlockPrefetch<4, 8, 16, 1>{}(baseoffset, width, height, pitch, coord);
#else
      CUTE_INVALID_CONTROL_PATH("Trying to use block prefetch on non-Xe hardware");
#endif
    }
  };
};

struct XE_2D_TF32x32x16_LD_N {
  using BlockShape = Shape<_32, _16>;
  using ValueShape = Shape<_16, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoad<4, 8, 32, 2>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};


struct XE_2D_U32x16x1_LD_T {
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoadTranspose<4, 1, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x16x2_LD_T {
  using BlockShape = Shape<_2, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoadTranspose<4, 2, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x16x4_LD_T {
  using BlockShape = Shape<_4, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoadTranspose<4, 4, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x16x8_LD_T {
  using BlockShape = Shape<_8, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockLoadTranspose<4, 8, 16, 1>{}(baseoffset, width, height, pitch, coord, dst);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }

  struct PREFETCH {
    CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                      int height, int pitch,
                                      intel::coord_t coord) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    detail::XeSubgroup2DBlockPrefetch<4, 8, 16, 1>{}(baseoffset, width, height, pitch, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-Xe hardware");
#endif
    }
  };
};

struct XE_2D_U32x1x16_ST_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    // static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockStore<4, 16, 1, 1>{}(baseoffset, width, height, pitch, coord, src);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x2x16_ST_N {
  using BlockShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockStore<4, 16, 2, 1>{}(baseoffset, width, height, pitch, coord, src);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x4x16_ST_N {
  using BlockShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockStore<4, 16, 4, 1>{}(baseoffset, width, height, pitch, coord, src);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

struct XE_2D_U32x8x16_ST_N {
  using BlockShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    // static_assert(sizeof(T) == 4, "Expected T to have size 4");
    detail::XeSubgroup2DBlockStore<4, 16, 8, 1>{}(baseoffset, width, height, pitch, coord, src);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-Xe hardware");
#endif
  }
};

} // end namespace cute
