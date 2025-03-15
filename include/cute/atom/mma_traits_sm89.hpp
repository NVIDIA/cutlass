#pragma once

#include <cute/arch/mma_sm89.hpp>
#include <cute/atom/mma_traits.hpp>
#include <cute/layout.hpp>
#include <cute/numeric/numeric_types.hpp>

namespace cute 
{

namespace {

// (T32,V4) -> (M16,N8)
using SM80_16x8_Row = Layout<Shape <Shape < _4,_8>,Shape < _2,_2>>,
                             Stride<Stride<_32,_1>,Stride<_16,_8>>>;

}

template <>
struct MMA_Traits<SM89_16x8x32_F32E4M3E4M3F32_TN> {
    using ValTypeD = float;
    using ValTypeA = float_e4m3_t;
    using ValTypeB = float_e4m3_t;
    using ValTypeC = float;

    using Shape_MNK = Shape<_16,_8,_32>;
    using ThrID   = Layout<_32>;
    using ALayout = Layout<Shape <Shape < _4,_8>,Shape < _4,_2,  _2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
    using BLayout = Layout<Shape <Shape < _4,_8>, Shape <_4,  _2>>,
                         Stride<Stride<_32,_1>, Stride<_8,_128>>>;
    using CLayout = SM80_16x8_Row;
};

template <>
struct MMA_Traits<SM89_16x8x32_F32E4M3E5M2F32_TN> : 
MMA_Traits<SM89_16x8x32_F32E4M3E4M3F32_TN> {
    using ValTypeD = float;
    using ValTypeA = float_e4m3_t;
    using ValTypeB = float_e5m2_t;
    using ValTypeC = float;
};

template <>
struct MMA_Traits<SM89_16x8x32_F32E5M2E5M2F32_TN> : 
MMA_Traits<SM89_16x8x32_F32E4M3E4M3F32_TN> {
    using ValTypeD = float;
    using ValTypeA = float_e5m2_t;
    using ValTypeB = float_e5m2_t;
    using ValTypeC = float;
};

template <>
struct MMA_Traits<SM89_16x8x32_F32E5M2E4M3F32_TN> : 
MMA_Traits<SM89_16x8x32_F32E4M3E4M3F32_TN> {
    using ValTypeD = float;
    using ValTypeA = float_e5m2_t;
    using ValTypeB = float_e4m3_t;
    using ValTypeC = float;
};

} // end namespace cute