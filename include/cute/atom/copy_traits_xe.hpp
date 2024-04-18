#pragma once

#include <cute/atom/copy_traits.hpp>
#include <cute/atom/copy_atom.hpp>

#include <cute/arch/copy_xe.hpp>

namespace cute
{
    template <class GTensor>
    struct Copy_Traits<XE_2D_LOAD, GTensor>
    {
        // using ThrID   = Layout<_16>; //TODO: I think it should be 16 (copy is per subgroup) - but static_assert fails
        using ThrID = Layout<_1>;
        using NumBits = Int<sizeof(typename GTensor::engine_type::value_type) * 8>; // hacky: does vec of 8
        // Map from (src-thr,src-val) to bit
        using SrcLayout = Layout<Shape<_1, NumBits>>; // TODO:  is _1 correct?
        // Map from (dst-thr,dst-val) to bit
        using DstLayout = Layout<Shape<_1, NumBits>>;
        // Reference map from (thr,val) to bit
        using RefLayout = SrcLayout;

        GTensor tensor;

        template <class TS, class SLayout,
                  class TD, class DLayout>
        CUTE_HOST_DEVICE friend constexpr void
        copy_unpack(Copy_Traits const &traits,
                    Tensor<ViewEngine<ArithmeticTupleIterator<TS>>, SLayout> const &src,
                    Tensor<TD, DLayout> &dst)
        {
            static_assert(is_rmem<TD>::value);
            int H = size<0>(traits.tensor);
            // int W = size<1>(traits.tensor) * sizeof(typename decltype(traits.tensor)::engine_type::value_type);
            int W = size<1>(traits.tensor) * sizeof(typename TD::value_type); //TODO: inconsistent to give the size in elements but use vector for copy
            auto [y, x] = src.data().coord_;
            XE_2D_LOAD::copy(traits.tensor.data().get(), W, H, W, int2_{x, y}, &*dst.data());
        }
    };


    template <class GTensor>
    struct Copy_Traits<XE_2D_SAVE, GTensor>
    {
        // using ThrID   = Layout<_16>; //TODO: I think it should be 16 (copy is per subgroup) - but static_assert fails
        using ThrID = Layout<_1>;
        using NumBits = Int<sizeof(typename GTensor::engine_type::value_type) * 8>; // hacky: does vec of 8
        // Map from (src-thr,src-val) to bit
        using SrcLayout = Layout<Shape<_1, NumBits>>; // TODO:  is _1 correct?
        // Map from (dst-thr,dst-val) to bit
        using DstLayout = Layout<Shape<_1, NumBits>>;
        // Reference map from (thr,val) to bit
        using RefLayout = SrcLayout;

        GTensor tensor;

        template <class TS, class SLayout,
                  class TD, class DLayout>
        CUTE_HOST_DEVICE friend constexpr void
        copy_unpack(Copy_Traits const &traits,
                    Tensor<TS, SLayout> const &src,
                    Tensor<ViewEngine<ArithmeticTupleIterator<TD>>, DLayout> &dst)
        {
            static_assert(is_rmem<TS>::value);
            int H = size<0>(traits.tensor);
            int W = size<1>(traits.tensor) * sizeof(typename decltype(traits.tensor)::engine_type::value_type);
            auto [y, x] = dst.data().coord_;
            XE_2D_SAVE::copy(traits.tensor.data().get(), W, H, W, int2_{x, y}, &*src.data());
        }
    };

    template <class Copy, class GEngine, class GLayout>
    auto make_xe_2d_copy(Tensor<GEngine, GLayout> gtensor)
    {
        using GTensor = Tensor<GEngine, GLayout>;
        using Traits = Copy_Traits<Copy, GTensor>;
        Traits traits{gtensor};
        return Copy_Atom<Traits, typename GEngine::value_type>{traits};
    }
}
