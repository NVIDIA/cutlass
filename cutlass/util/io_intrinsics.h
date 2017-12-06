/******************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#pragma once

/**
 * \file
 * \brief I/O device intrinsics
 */

#include <stdint.h>
#include <cuda_fp16.h>

#include "nv_std.h"
#include "math.h"

namespace cutlass {




/******************************************************************************
 * io_vector
 ******************************************************************************/

/**
 * Base aligned storage for IO vector
 */
template <typename value_t, int VectorItems, int AlignBytes> struct io_vector_base;
template <typename value_t, int VectorItems> struct __align__(1) io_vector_base<value_t, VectorItems, 1> { value_t buff[VectorItems]; };
template <typename value_t, int VectorItems> struct __align__(2) io_vector_base<value_t, VectorItems, 2> { value_t buff[VectorItems]; };
template <typename value_t, int VectorItems> struct __align__(4) io_vector_base<value_t, VectorItems, 4> { value_t buff[VectorItems]; };
template <typename value_t, int VectorItems> struct __align__(8) io_vector_base<value_t, VectorItems, 8> { value_t buff[VectorItems]; };
template <typename value_t, int VectorItems> struct __align__(16) io_vector_base<value_t, VectorItems, 16> { value_t buff[VectorItems]; };


/**
 * \brief Aligned vector type for coarsening data movement instructions
 *
 * Exposes the member constant \p VectorItems, the actual number of component
 * values comprising the io_vector
 */
template <
    typename value_t,                                                           ///< Component value type
    int MaxVectorItems,                                                         ///< Maximum allowable component values
    int MaxAlignBytes                                                           ///< Maximum allowable alignment
            = __NV_STD_MIN(16, MaxVectorItems * sizeof(value_t)),
    int AlignBytes                                                              ///< Actual alignment
            = __NV_STD_MIN(sizeof(value_t) * MaxVectorItems, MaxAlignBytes),
    int VectorItems                                                             ///< Actual number of component values
            = divide_assert<AlignBytes, sizeof(value_t)>::value,
    bool MustAlias                                                              ///< Whether we need to alias during loads/stores
            = (VectorItems > 4)>
struct io_vector;


/**
 * IO vector (specialization for VectorItems <= 4)
 */
template <
    typename value_t,
    int MaxVectorItems,
    int MaxAlignBytes,
    int _AlignBytes,
    int _VectorItems>
struct io_vector <
    value_t,
    MaxVectorItems,
    MaxAlignBytes,
    _AlignBytes,
    _VectorItems,
    false>
:
    io_vector_base<value_t, _VectorItems, _AlignBytes>
{
    enum
    {
        VectorItems = _VectorItems,
        AlignBytes = _AlignBytes
    };

    static_assert(is_pow2<AlignBytes>::value, "I/O vector alignment must be a power-of-two.");
    static_assert((AlignBytes <= 16), "I/O vector alignment must <= 16B.");

    inline __device__
    void load(const io_vector *ptr)
    {
        *this = *ptr;
    }

    inline __device__
    void load(const value_t *ptr)
    {
        *this = *reinterpret_cast<const io_vector*>(ptr);
    }


    inline __device__
    void store(io_vector *ptr) const
    {
        *ptr = *this;
    }

    inline __device__
    void store(value_t *ptr) const
    {
        *reinterpret_cast<io_vector*>(ptr) = *this;
    }
};


/**
 * IO vector (specialization for VectorItems > 4)
 *
 * NB: Workaround for NVCC not generating 128-bit loads/stores for aligned
 * structures having component types < 32b
 */
template <
    typename value_t,
    int MaxVectorItems,
    int MaxAlignBytes,
    int _AlignBytes,
    int _VectorItems>
struct io_vector <
    value_t,
    MaxVectorItems,
    MaxAlignBytes,
    _AlignBytes,
    _VectorItems,
    true>
:
    io_vector_base<value_t, _VectorItems, _AlignBytes>
{
    enum
    {
        VectorItems = _VectorItems,
        AlignBytes = _AlignBytes
    };

    static_assert(is_pow2<AlignBytes>::value, "I/O vector alignment must be a power-of-two.");
    static_assert((AlignBytes <= 16), "I/O vector alignment must <= 16B.");

    typedef typename nv_std::conditional<(AlignBytes == 8),
            uint2,  // Use 8B load
            uint4>  // Use 16B load
        ::type align_t;

    inline __device__
    void load(const io_vector *ptr)
    {
        *reinterpret_cast<align_t*>(this) = *reinterpret_cast<const align_t*>(ptr);
    }

    inline __device__
    void load(const value_t *ptr)
    {
        *reinterpret_cast<align_t*>(this) = *reinterpret_cast<const align_t*>(ptr);
    }


    inline __device__
    void store(io_vector *ptr) const
    {
        *reinterpret_cast<align_t*>(ptr) = *reinterpret_cast<const align_t*>(this);
    }

    inline __device__
    void store(value_t *ptr) const
    {
        *reinterpret_cast<align_t*>(ptr) = *reinterpret_cast<const align_t*>(this);
    }

};







/******************************************************************************
 * Macro expansions for vector loads
 ******************************************************************************/

/**
 * Define vector-4 LD specialization for the given load modifier
 */
#define CUTLASS_LD_V4(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint) \
    template <typename ptr_t>                                                                   \
    inline __device__                                                                           \
    void f_name(                                                                                \
        value_t (&dest)[4],                                                                     \
        ptr_t ptr)                                                                              \
    {                                                                                           \
        asm volatile ("ld."#load_modifier".v4."#ptx_type" {%0, %1, %2, %3}, [%4];\n"            \
            :                                                                                   \
                "="#val_constraint(dest[0]),                                                    \
                "="#val_constraint(dest[1]),                                                    \
                "="#val_constraint(dest[2]),                                                    \
                "="#val_constraint(dest[3])                                                     \
            :                                                                                   \
                #ptr_constraint(ptr));                                                          \
    }

/**
 * Define vector-2 LD specialization for the given load modifier
 */
#define CUTLASS_LD_V2(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint) \
    template <typename ptr_t>                                                                   \
    inline __device__                                                                           \
    void f_name(                                                                                \
        value_t (&dest)[2],                                                                     \
        ptr_t ptr)                                                                              \
    {                                                                                           \
        asm volatile ("ld."#load_modifier".v2."#ptx_type" {%0, %1}, [%2];\n"                    \
            :                                                                                   \
                "="#val_constraint(dest[0]),                                                    \
                "="#val_constraint(dest[1])                                                     \
            :                                                                                   \
                #ptr_constraint(ptr));                                                          \
    }


/**
 * Define vector-1 LD specialization for the given load modifier
 */
#define CUTLASS_LD_V1(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint) \
    template <typename ptr_t>                                                                   \
    inline __device__                                                                           \
    void f_name(                                                                                \
        value_t (&dest)[1],                                                                     \
        ptr_t ptr)                                                                              \
    {                                                                                           \
        asm volatile ("ld."#load_modifier"."#ptx_type" %0, [%1];\n"                             \
            :                                                                                   \
                "="#val_constraint(dest[0])                                                     \
            :                                                                                   \
                #ptr_constraint(ptr));                                                          \
    }


/**
 * Define powers-of-two vector LD specializations
 */
#define CUTLASS_LD_ALL(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)    \
    CUTLASS_LD_V4(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)         \
    CUTLASS_LD_V2(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)         \
    CUTLASS_LD_V1(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)


/******************************************************************************
 * Macro expansions for vector stores
 ******************************************************************************/

/**
 * Define vector-4 ST specialization for the given load modifier
 */
#define CUTLASS_ST_V4(f_name, value_t, store_modifier, ptx_type, val_constraint, ptr_constraint)    \
    template <typename ptr_t>                                                                       \
    inline __device__                                                                               \
    void f_name(                                                                                    \
        ptr_t ptr,                                                                                  \
        const value_t (&src)[4])                                                                    \
    {                                                                                               \
        asm volatile ("st."#store_modifier".v4."#ptx_type" [%0], {%1, %2, %3, %4};\n"               \
            : :                                                                                     \
                #ptr_constraint(ptr),                                                               \
                #val_constraint(src[0]),                                                            \
                #val_constraint(src[1]),                                                            \
                #val_constraint(src[2]),                                                            \
                #val_constraint(src[3]));                                                           \
    }


/**
 * Define vector-2 ST specialization for the given load modifier
 */
#define CUTLASS_ST_V2(f_name, value_t, store_modifier, ptx_type, val_constraint, ptr_constraint)    \
    template <typename ptr_t>                                                                       \
    inline __device__                                                                               \
    void f_name(                                                                                    \
        ptr_t ptr,                                                                                  \
        const value_t (&src)[2])                                                                    \
    {                                                                                               \
        asm volatile ("st."#store_modifier".v2."#ptx_type" [%0], {%1, %2};\n"                       \
            : :                                                                                     \
                #ptr_constraint(ptr),                                                               \
                #val_constraint(src[0]),                                                            \
                #val_constraint(src[1]));                                                           \
    }

/**
 * Define vector-1 ST specialization for the given load modifier
 */
#define CUTLASS_ST_V1(f_name, value_t, store_modifier, ptx_type, val_constraint, ptr_constraint)    \
    template <typename ptr_t>                                                                       \
    inline __device__                                                                               \
    void f_name(                                                                                    \
        ptr_t ptr,                                                                                  \
        const value_t (&src)[1])                                                                    \
    {                                                                                               \
        asm volatile ("st."#store_modifier"."#ptx_type" [%0], %1;\n"                                \
            : :                                                                                     \
                #ptr_constraint(ptr),                                                               \
                #val_constraint(src[0]));                                                           \
    }


/**
 * Define powers-of-two vector LD specializations
 */
#define CUTLASS_ST_ALL(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)    \
    CUTLASS_ST_V4(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)         \
    CUTLASS_ST_V2(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)         \
    CUTLASS_ST_V1(f_name, value_t, load_modifier, ptx_type, val_constraint, ptr_constraint)



/******************************************************************************
 * Macro expansions for vector IO
 ******************************************************************************/

/**
 * Define global and shared LD specializations
 */
#define CUTLASS_IO(value_t, ptx_type, val_constraint)                                       \
    CUTLASS_LD_ALL(ldg_cg_internal, value_t, global.cg, ptx_type, val_constraint, l)        \
    CUTLASS_ST_ALL(stg_cg_internal, value_t, global.cg, ptx_type, val_constraint, l)


// Define IO for useful types
CUTLASS_IO(double,     f64, d)
CUTLASS_IO(float,      f32, f)
CUTLASS_IO(int64_t,    b64, l)
CUTLASS_IO(int32_t,    b32, r)
CUTLASS_IO(int16_t,    b16, h)


// Macro cleanup
#undef CUTLASS_IO
#undef CUTLASS_LD_ALL
#undef CUTLASS_LD_V4
#undef CUTLASS_LD_V2
#undef CUTLASS_LD_V1
#undef CUTLASS_ST_ALL
#undef CUTLASS_ST_V4
#undef CUTLASS_ST_V2
#undef CUTLASS_ST_V1


/******************************************************************************
 * I/O cast types
 ******************************************************************************/

/// Provides the type for which to reinterpret-cast a given vector
template <
    typename value_t,
    int IoVecDim,
    int ValueBytes = sizeof(value_t)>
struct io_cast
{
    typedef value_t type[IoVecDim];
};


/// Provides the type for which to reinterpret-cast a vector of 1B types
template <
    typename value_t,
    int IoVecDim>
struct io_cast<value_t, IoVecDim, 1>
{
    typedef typename nv_std::conditional<
            (IoVecDim < 2),
            int8_t[1],                                 // Use 8b load
            typename nv_std::conditional<
                (IoVecDim < 4),
                int16_t[1],                            // Use 16b load
                int32_t[IoVecDim / 4]>::type>::type    // Use up to 128b load
        type;
};


/// Provides the type for which to reinterpret-cast a vector of 2B types
template <
    typename value_t,
    int IoVecDim>
struct io_cast<value_t, IoVecDim, 2>
{
    typedef typename nv_std::conditional<
            (IoVecDim < 2),
            int16_t[1],                                // Use 16b load
            int32_t[IoVecDim / 2]>::type               // Use up to 128b load
        type;
};



/******************************************************************************
 * ldg_cg intrinsics
 ******************************************************************************/

/// Load from global (cache-global modifier)
template <typename value_t, typename ptr_t>
inline __device__
void ldg_cg(
    value_t &dest,
    ptr_t d_in)
{
    // Cast dest to a different array type if necessary
    ldg_cg_internal(
        reinterpret_cast<typename io_cast<value_t, 1>::type &>(dest),
        d_in);
}

/// Load from global (cache-global modifier)
template <typename value_t, int IoVecDim, typename ptr_t>
inline __device__
void ldg_cg(
    value_t (&dest)[IoVecDim],
    ptr_t d_in)
{
    static_assert(is_pow2<IoVecDim>::value, "I/O vectors must be a power-of-two.");

    // Cast dest to a different array type if necessary
    ldg_cg_internal(
        reinterpret_cast<typename io_cast<value_t, IoVecDim>::type &>(dest),
        d_in);
}


/******************************************************************************
 * stg_cg intrinsics
 ******************************************************************************/

/// Store to global (cache-global modifier)
template <typename ptr_t, typename value_t>
inline __device__
void stg_cg(
    ptr_t dest,
    const value_t &src)
{
    // Cast src to a different array type if necessary
    stg_cg_internal(
        dest,
        reinterpret_cast<const typename io_cast<value_t, 1>::type &>(src));
}

/// Store to global (cache-global modifier)
template <typename ptr_t, int IoVecDim, typename value_t>
inline __device__
void stg_cg(
    ptr_t dest,
    const value_t (&src)[IoVecDim])
{
    static_assert(is_pow2<IoVecDim>::value, "I/O vectors must be a power-of-two.");

    // Cast src to a different array type if necessary
    stg_cg_internal(
        dest,
        reinterpret_cast<const typename io_cast<value_t, IoVecDim>::type &>(src));
}





} // namespace cutlass

