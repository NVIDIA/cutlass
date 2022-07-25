#pragma once
#include <cutlass/cutlass.h>
#include <cutlass/matrix.h>

namespace cutlass {
namespace contrib {

/// Argument def of tensor
template <typename Element_, typename Layout_, int Alignment, typename ParamOp_ = nullptr_t>
struct TensorDef {
  using Element = Element_;
  using Layout = Layout_;
  using ParamOp = ParamOp_;
  static constexpr int kAlignment = Alignment;
};

template <typename Element_>
struct TensorParams {
  using Element = Element_;

  Element* ptr = nullptr;
  int32_t ldm = 0;
};

template <typename Element_>
class DefaultTensorParamGeneratorOp {
 public:
  using Element = Element_;
  struct Params {
    Element* ptr;
    int ldm;
    int64_t batch_stride;
    int64_t problem_stride;
  };

 private:
  Element* ptr_;
  int const ldm_;
  int64_t const batch_stride_;
  int64_t const problem_stride_;

 public:
  CUTLASS_HOST_DEVICE
  DefaultTensorParamGeneratorOp() : ptr_(nullptr), ldm_(0), batch_stride_(0), problem_stride_(0) {
  }

  CUTLASS_HOST_DEVICE
  DefaultTensorParamGeneratorOp(Params const& params)
      : ptr_(params.ptr),
        ldm_(params.ldm),
        batch_stride_(params.batch_stride),
        problem_stride_(params.problem_stride) {
  }
  CUTLASS_DEVICE
  TensorParams<Element> operator()(int problem_idx, int batch_idx) const {
    TensorParams<Element> ret;
    ret.ldm = ldm_;
    ret.ptr = ptr_ + problem_idx * problem_stride_ + batch_idx * batch_stride_;
    return ret;
  }
};

struct IdentityPrologueOperator {
 public:
  template <typename WarpLoadIterator>
  struct Detail {
    using Fragment = int;
  };
  struct Params {};

 public:
  CUTLASS_HOST_DEVICE
  IdentityPrologueOperator(Params const& params,
                           int problem_idx,
                           int batch_idx,
                           cutlass::MatrixCoord extent,
                           cutlass::MatrixCoord warp_offsets) {
  }

  template <typename WarpLoadIterator>
  CUTLASS_DEVICE void operator++() {
  }

  template <typename WarpLoadIterator>
  CUTLASS_HOST_DEVICE void set_kgroup_index(int k_group) {
  }

  template <typename WarpLoadIterator>
  CUTLASS_DEVICE void load(typename Detail<WarpLoadIterator>::Fragment& frag) {
  }

  template <typename WarpLoadIterator>
  CUTLASS_HOST_DEVICE typename WarpLoadIterator::Fragment operator()(
      typename WarpLoadIterator::Fragment const& mma_frag,
      typename Detail<WarpLoadIterator>::Fragment const& frag) const {
    return mma_frag;
  }
};

/// Prologue def
template <typename Operator_ = IdentityPrologueOperator>
struct PrologueDef {
  using Operator = Operator_;
  using Params = typename Operator::Params;
};

template <typename TensorDef_, typename Operator_>
struct EpilogueDef {
  using TensorDef = TensorDef_;
  using Operator = Operator_;
};

template <typename ThreadblockShape_, typename WarpShape_, typename InstructionShape_>
struct TileShapeDef {
  using ThreadblockShape = ThreadblockShape_;
  using WarpShape = WarpShape_;
  using InstructionShape = InstructionShape_;
  static constexpr int kPartitionsK = ThreadblockShape::kK / WarpShape::kK;
};

}  // namespace contrib
}  // namespace cutlass