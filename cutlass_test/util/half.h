/******************************************************************************
 * Copyright (c) 2011-2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are not permitted.
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
 * Utilities for interacting with the opaque CUDA __half type
 */

#include <stdint.h>
#include <cuda_fp16.h>
#include <iosfwd>

namespace cutlass {


/******************************************************************************
 * half_t
 ******************************************************************************/

/**
 * Host-based fp16 data type compatible and convertible with __half
 */
struct half_t
{
    uint16_t __x;

    /// Constructor from __half
    half_t(const __half &other)
    {
        __x = reinterpret_cast<const uint16_t&>(other);
    }

    /// Constructor from integer
    half_t(int a)
    {
        *this = half_t(float(a));
    }


    /// Constructor from float
    half_t(float a)
    {
        uint32_t ia = *reinterpret_cast<uint32_t*>(&a);
        uint16_t ir;

        ir = (ia >> 16) & 0x8000;

        if ((ia & 0x7f800000) == 0x7f800000)
        {
            if ((ia & 0x7fffffff) == 0x7f800000)
            {
                ir |= 0x7c00; /* infinity */
            }
            else
            {
                ir = 0x7fff; /* canonical NaN */
            }
        }
        else if ((ia & 0x7f800000) >= 0x33000000)
        {
            int32_t shift = (int32_t) ((ia >> 23) & 0xff) - 127;
            if (shift > 15)
            {
                ir |= 0x7c00; /* infinity */
            }
            else
            {
                ia = (ia & 0x007fffff) | 0x00800000; /* extract mantissa */
                if (shift < -14)
                { /* denormal */
                    ir |= ia >> (-1 - shift);
                    ia = ia << (32 - (-1 - shift));
                }
                else
                { /* normal */
                    ir |= ia >> (24 - 11);
                    ia = ia << (32 - (24 - 11));
                    ir = ir + ((14 + shift) << 10);
                }
                /* IEEE-754 round to nearest of even */
                if ((ia > 0x80000000) || ((ia == 0x80000000) && (ir & 1)))
                {
                    ir++;
                }
            }
        }

        this->__x = ir;
    }

    /// Cast to __half
    operator __half() const
    {
        return reinterpret_cast<const __half&>(__x);
    }

    /// Cast to float
    operator float() const
    {
        int sign        = ((this->__x >> 15) & 1);
        int exp         = ((this->__x >> 10) & 0x1f);
        int mantissa    = (this->__x & 0x3ff);
        uint32_t f      = 0;

        if (exp > 0 && exp < 31)
        {
            // normal
            exp += 112;
            f = (sign << 31) | (exp << 23) | (mantissa << 13);
        }
        else if (exp == 0)
        {
            if (mantissa)
            {
                // subnormal
                exp += 113;
                while ((mantissa & (1 << 10)) == 0)
                {
                    mantissa <<= 1;
                    exp--;
                }
                mantissa &= 0x3ff;
                f = (sign << 31) | (exp << 23) | (mantissa << 13);
            }
            else
            {
                // zero
                f = 0;
            }
        }
        else if (exp == 31)
        {
            if (mantissa)
            {
                f = 0x7fffffff;     // not a number
            }
            else
            {
                f = (0xff << 23) | (sign << 31);    //  inf
            }
        }
        return *reinterpret_cast<float const *>(&f);
    }


    /// Get raw storage
    uint16_t raw()
    {
        return this->__x;
    }

    /// Assignment by sum
    bool operator ==(const half_t &other)
    {
        return (this->__x == other.__x);
    }

    /// Increment
    half_t& operator +=(const half_t &rhs)
    {
        *this = half_t(float(*this) + float(rhs));
        return *this;
    }
    
    /// Decrement
    half_t& operator -=(const half_t &rhs)
    {
        *this = half_t(float(*this) - float(rhs));
        return *this;
    }

    /// Multiply
    half_t operator*(const half_t &other)
    {
        return half_t(float(*this) * float(other));
    }

    /// Multiply
    half_t operator+(const half_t &other)
    {
        return half_t(float(*this) + float(other));
    }

};


/******************************************************************************
 * I/O stream overloads
 ******************************************************************************/

/// Insert formatted \p half_t into the output stream
std::ostream& operator<<(std::ostream &out, const half_t &x)
{
    out << (float)x;
    return out;
}


/// Insert formatted \p __half into the output stream
std::ostream& operator<<(std::ostream &out, const __half &x)
{
    return out << half_t(x);
}


} // namespace cutlass
