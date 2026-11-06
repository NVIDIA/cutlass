// clang-format off
/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
// clang-format on

//===- ExpandOps.cpp - Expand selected cute ops --------------------------===//
//

//===----------------------------------------------------------------------===//

#include "cute_ir/Conversion/CuteToBase/Passes.h"
#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"
#include "cute_ir/Dialect/Cute/Transforms/StaticFold.h"

#include "cutegen/cutegen_mlir.hpp"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Matchers.h"
#include "mlir/Transforms/DialectConversion.h"

#include "llvm/ADT/TypeSwitch.h"
#include "llvm/Support/FormatVariadic.h"

namespace mlir::cutlass_compiler::cute {
#define GEN_PASS_DEF_CUTEEXPANDOPS
#include "cute_ir/Conversion/CuteToBase/Passes.h.inc"
} // namespace mlir::cutlass_compiler::cute

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
namespace cg = cutegen;

namespace {

/// Materialize a cutegen value from a cute SSA value. Static values are
/// returned as-is; dynamic values are produced via cute.get_scalars and
/// bound through @p listener. @p TyClass is the cute MLIR type class (e.g.
/// LayoutType, ShapeType) used to recover the cutegen ref from the
/// operand's type.
template <typename TyClass>
auto buildCutegenFromCuteValue(ImplicitLocOpBuilder &b, Value src,
                               cg::dynamic_listener *listener) {
  auto tuple = llvm::cast<TyClass>(src.getType()).getRef();
  if (cg::is_static(tuple)) {
    return tuple;
  }
  ValueRange scalars =
      GetScalarsOp::create(b, src, /*only_dynamic=*/true).getScalars();
  cg::set_with_mlir_values(listener, tuple, scalars);
  return tuple;
}

/// Build a !cute.layout SSA value from a cutegen layout. Static layouts
/// become cute.static; dynamic layouts are rebuilt with make_shape +
/// make_stride + make_layout.
Value buildLayout(ImplicitLocOpBuilder &b, cg::layout lay) {
  if (cg::is_static(lay)) {
    auto layoutTy = LayoutType::get(b.getContext(), std::move(lay));
    return StaticOp::create(b, layoutTy).getResult();
  }
  Value shape = MakeShapeOp::create(b, lay.shape()).getResult();
  Value stride = MakeStrideOp::create(b, lay.stride()).getResult();
  return MakeLayoutOp::create(b, shape, stride).getResult();
}

/// Build a !cute.composed_layout SSA value from a cutegen composed layout.
/// Static composed layouts become cute.static. Dynamic composed layouts
/// are rebuilt from inner/offset/outer; when @p allowDecay and the value is
/// a normal layout (no swizzle, zero offset), the outer layout is returned
/// directly to avoid a redundant wrap.
[[maybe_unused]] Value buildLayout(ImplicitLocOpBuilder &b,
                                   cg::composed_layout lay,
                                   bool allowDecay = true) {
  if (cg::is_static(lay)) {
    auto resTy = ComposedLayoutType::get(
        b.getContext(),
        ComposedLayoutAttr::get(b.getContext(), std::move(lay)));
    return StaticOp::create(b, resTy).getResult();
  }
  Value outer = buildLayout(b, lay.layout_b());
  if (lay.is_normal_layout() && allowDecay) {
    return outer;
  }
  Value offset = MakeIntTupleOp::create(b, lay.offset()).getResult();
  if (lay.is_a_affine()) {
    Value inner = buildLayout(b, lay.layout_a());
    return MakeComposedLayoutOp::create(b, inner, offset, outer).getResult();
  }
  auto swizzleTy = SwizzleType::get(
      b.getContext(), SwizzleAttr::get(b.getContext(), lay.swizzle_a()));
  Value inner = StaticOp::create(b, swizzleTy).getResult();
  return MakeComposedLayoutOp::create(b, inner, offset, outer).getResult();
}

/// Build a !cute.int_tuple SSA value from a cutegen int_tuple.
Value buildArithTuple(ImplicitLocOpBuilder &b, cg::int_tuple tuple) {
  return MakeIntTupleOp::create(b, std::move(tuple)).getResult();
}

/// Build a !cute.shape SSA value from a cutegen shape.
Value buildArithTuple(ImplicitLocOpBuilder &b, cg::shape shape) {
  return MakeShapeOp::create(b, std::move(shape)).getResult();
}

/// Build a !cute.stride SSA value from a cutegen stride.
Value buildArithTuple(ImplicitLocOpBuilder &b, cg::stride stride) {
  return MakeStrideOp::create(b, std::move(stride)).getResult();
}

/// Build a !cute.coord SSA value from a cutegen coord.
Value buildArithTuple(ImplicitLocOpBuilder &b, cg::coord coord) {
  return MakeCoordOp::create(b, std::move(coord)).getResult();
}

/// Build a !cute.tile SSA value from a cutegen tile.
Value buildTile(ImplicitLocOpBuilder &b, cg::tile tile) {
  return MakeTileOp::create(b, std::move(tile)).getResult();
}

//===----------------------------------------------------------------------===//
// MakeLayoutLikeOp (cute.make_layout_like)
//===----------------------------------------------------------------------===//

struct MakeLayoutLikeOpConversion final
    : public OpConversionPattern<MakeLayoutLikeOp> {
  using OpConversionPattern<MakeLayoutLikeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MakeLayoutLikeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto srcTy = op.getSrc().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(srcTy)
        .Case<LayoutType>([&](LayoutType) {
          auto src = buildCutegenFromCuteValue<LayoutType>(b, adaptor.getSrc(),
                                                           &listener);
          cg::layout res = cg::make_layout_like(src);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Case<ComposedLayoutType>([&](ComposedLayoutType) {
          auto src = buildCutegenFromCuteValue<ComposedLayoutType>(
              b, adaptor.getSrc(), &listener);
          cg::layout res = cg::make_layout_like(src);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $src to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// MakeOrderedLayoutOp (cute.make_ordered_layout)
//===----------------------------------------------------------------------===//

struct MakeOrderedLayoutOpConversion final
    : public OpConversionPattern<MakeOrderedLayoutOp> {
  using OpConversionPattern<MakeOrderedLayoutOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MakeOrderedLayoutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getLayout().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto shape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);
    auto order = buildCutegenFromCuteValue<IntTupleType>(b, adaptor.getOrder(),
                                                         &listener);
    cg::layout res(shape, cg::compact_order<cg::stride>(shape, order));
    rewriter.replaceOp(op, buildLayout(b, res));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// MakeIdentityLayoutOp (cute.make_identity_layout)
//===----------------------------------------------------------------------===//

struct MakeIdentityLayoutOpConversion final
    : public OpConversionPattern<MakeIdentityLayoutOp> {
  using OpConversionPattern<MakeIdentityLayoutOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MakeIdentityLayoutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto shape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);
    cg::layout res = cg::make_identity_layout(shape);
    rewriter.replaceOp(op, buildLayout(b, res));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// GetShapeOp (cute.get_shape)
//===----------------------------------------------------------------------===//

struct GetShapeOpConversion final : public OpConversionPattern<GetShapeOp> {
  using OpConversionPattern<GetShapeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetShapeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<ShapeType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto inputTy = op.getInput().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
        .Case<LayoutType>([&](LayoutType) {
          auto cgInput = buildCutegenFromCuteValue<LayoutType>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op,
                             buildArithTuple(b, cg::shape(cgInput.shape())));
          return success();
        })
        .Case<ComposedLayoutType>([&](ComposedLayoutType) {
          auto cgInput = buildCutegenFromCuteValue<ComposedLayoutType>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op,
                             buildArithTuple(b, cg::shape(cgInput.shape())));
          return success();
        })
        .Case<TileType>([&](TileType) {
          auto cgInput = buildCutegenFromCuteValue<TileType>(
              b, adaptor.getInput(), &listener);
          cg::shape res = cg::extract_shape_from_tile(cgInput);
          rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType|TileType");
        });
  }
};

//===----------------------------------------------------------------------===//
// GetStrideOp (cute.get_stride)
//===----------------------------------------------------------------------===//

struct GetStrideOpConversion final : public OpConversionPattern<GetStrideOp> {
  using OpConversionPattern<GetStrideOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetStrideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<StrideType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgInput =
        buildCutegenFromCuteValue<LayoutType>(b, adaptor.getInput(), &listener);
    rewriter.replaceOp(op, buildArithTuple(b, cg::stride(cgInput.stride())));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ComposedGetInnerOp (cute.composed_get_inner)
//===----------------------------------------------------------------------===//

struct ComposedGetInnerOpConversion final
    : public OpConversionPattern<ComposedGetInnerOp> {
  using OpConversionPattern<ComposedGetInnerOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ComposedGetInnerOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgInput = buildCutegenFromCuteValue<ComposedLayoutType>(
        b, adaptor.getInput(), &listener);

    if (llvm::isa<LayoutType>(resTy)) {
      if (!cgInput.is_a_affine()) {
        return rewriter.notifyMatchFailure(
            op, "expected affine inner for layout result");
      }
      rewriter.replaceOp(op, buildLayout(b, cgInput.layout_a()));
      return success();
    }
    // Swizzle inner: the swizzle is always static; even when the composed
    // input is dynamic, the swizzle parameters are compile-time constants.
    rewriter.replaceOp(op, StaticOp::create(b, resTy));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ComposedGetOffsetOp (cute.composed_get_offset)
//===----------------------------------------------------------------------===//

struct ComposedGetOffsetOpConversion final
    : public OpConversionPattern<ComposedGetOffsetOp> {
  using OpConversionPattern<ComposedGetOffsetOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ComposedGetOffsetOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgInput = buildCutegenFromCuteValue<ComposedLayoutType>(
        b, adaptor.getInput(), &listener);
    rewriter.replaceOp(op, buildArithTuple(b, cg::int_tuple(cgInput.offset())));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ComposedGetOuterOp (cute.composed_get_outer)
//===----------------------------------------------------------------------===//

struct ComposedGetOuterOpConversion final
    : public OpConversionPattern<ComposedGetOuterOp> {
  using OpConversionPattern<ComposedGetOuterOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ComposedGetOuterOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgInput = buildCutegenFromCuteValue<ComposedLayoutType>(
        b, adaptor.getInput(), &listener);
    rewriter.replaceOp(op, buildLayout(b, cgInput.layout_b()));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ToIntTupleOp (cute.to_int_tuple)
//===----------------------------------------------------------------------===//

struct ToIntTupleOpConversion final : public OpConversionPattern<ToIntTupleOp> {
  using OpConversionPattern<ToIntTupleOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ToIntTupleOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto srcTy = op.getSrc().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(srcTy)
        .Case<ShapeType, StrideType, CoordType, IntTupleType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgSrc = buildCutegenFromCuteValue<TyClass>(b, adaptor.getSrc(),
                                                          &listener);
          rewriter.replaceOp(
              op, buildArithTuple(b, cg::rec_var_cast<cg::int_tuple>(cgSrc)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $src to "
                           "ShapeType|StrideType|CoordType|IntTupleType");
        });
  }
};

//===----------------------------------------------------------------------===//
// ToShapeOp (cute.to_shape)
//===----------------------------------------------------------------------===//

struct ToShapeOpConversion final : public OpConversionPattern<ToShapeOp> {
  using OpConversionPattern<ToShapeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ToShapeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<ShapeType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgSrc =
        buildCutegenFromCuteValue<IntTupleType>(b, adaptor.getSrc(), &listener);
    rewriter.replaceOp(op,
                       buildArithTuple(b, cg::rec_var_cast<cg::shape>(cgSrc)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ToStrideOp (cute.to_stride)
//===----------------------------------------------------------------------===//

struct ToStrideOpConversion final : public OpConversionPattern<ToStrideOp> {
  using OpConversionPattern<ToStrideOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ToStrideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<StrideType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgSrc =
        buildCutegenFromCuteValue<IntTupleType>(b, adaptor.getSrc(), &listener);
    rewriter.replaceOp(op,
                       buildArithTuple(b, cg::rec_var_cast<cg::stride>(cgSrc)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ToCoordOp (cute.to_coord)
//===----------------------------------------------------------------------===//

struct ToCoordOpConversion final : public OpConversionPattern<ToCoordOp> {
  using OpConversionPattern<ToCoordOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ToCoordOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<CoordType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgSrc =
        buildCutegenFromCuteValue<IntTupleType>(b, adaptor.getSrc(), &listener);
    rewriter.replaceOp(op,
                       buildArithTuple(b, cg::rec_var_cast<cg::coord>(cgSrc)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// GetLayoutsFromTileOp (cute.get_layouts_from_tile)
//===----------------------------------------------------------------------===//

struct GetLayoutsFromTileOpConversion final
    : public OpConversionPattern<GetLayoutsFromTileOp> {
  using OpConversionPattern<GetLayoutsFromTileOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetLayoutsFromTileOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    cg::dynamic_listener listener(b);
    auto cgInput =
        buildCutegenFromCuteValue<TileType>(b, adaptor.getTile(), &listener);

    cg::tile flatTile = cg::flatten(cgInput);
    SmallVector<Value> replacement;
    replacement.reserve(op.getNumResults());
    for (auto i : llvm::seq<size_t>(cg::rank(flatTile))) {
      if (!std::holds_alternative<cg::layout>(flatTile[i])) {
        continue;
      }
      auto layoutTy =
          llvm::cast<LayoutType>(op.getResultTypes()[replacement.size()]);
      if (cg::is_static(layoutTy.getRef())) {
        replacement.push_back(StaticOp::create(b, layoutTy).getResult());
        continue;
      }
      replacement.push_back(buildLayout(b, std::get<cg::layout>(flatTile[i])));
    }
    if (replacement.size() != op.getNumResults()) {
      return rewriter.notifyMatchFailure(
          op, llvm::formatv("expected {0} layout results, but got {1}",
                            op.getNumResults(), replacement.size()));
    }
    rewriter.replaceOp(op, replacement);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// GetLeavesOp (cute.get_leaves)
//===----------------------------------------------------------------------===//

struct GetLeavesOpConversion final : public OpConversionPattern<GetLeavesOp> {
  using OpConversionPattern<GetLeavesOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetLeavesOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    cg::dynamic_listener listener(b);

    /// Common driver for tuple-like inputs. Dispatches per-leaf to
    /// @p buildLeafValue when the result slot is dynamic.
    auto replaceTupleLikeLeaves = [&](const auto &cgInput,
                                      auto buildLeafValue) -> LogicalResult {
      auto flat = cg::flatten(cgInput);
      if (cg::rank(flat) != op.getNumResults()) {
        return rewriter.notifyMatchFailure(
            op, llvm::formatv("expected {0} flattened leaves but got {1}",
                              op.getNumResults(), cg::rank(flat)));
      }
      SmallVector<Value> replacement;
      replacement.reserve(op.getNumResults());
      for (auto i : llvm::seq<size_t>(op.getNumResults())) {
        Type resTy = op.getResultTypes()[i];
        if (auto maybeStatic = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
            maybeStatic && maybeStatic.isStatic()) {
          replacement.push_back(StaticOp::create(b, resTy).getResult());
          continue;
        }
        replacement.push_back(buildLeafValue(flat[i], resTy));
      }
      rewriter.replaceOp(op, replacement);
      return success();
    };

    auto inputTy = op.getInput().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
        .Case<IntTupleType, ShapeType, StrideType, CoordType>([&](auto ty) {
          using TyClass = decltype(ty);
          using CgT = typename TyClass::algebra_t;
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          return replaceTupleLikeLeaves(
              cgInput, [&](const auto &leaf, Type) -> Value {
                return buildArithTuple(b, cg::rec_var_cast<CgT>(leaf));
              });
        })
        .Case<TileType>([&](TileType) {
          auto cgInput = buildCutegenFromCuteValue<TileType>(
              b, adaptor.getInput(), &listener);
          return replaceTupleLikeLeaves(
              cgInput, [&](const auto &leaf, Type resTy) -> Value {
                if (llvm::isa<LayoutType>(resTy)) {
                  return buildLayout(b, std::get<cg::layout>(leaf));
                }
                return buildTile(b, leaf);
              });
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "ShapeType|StrideType|CoordType|IntTupleType|"
                           "TileType");
        });
  }
};

//===----------------------------------------------------------------------===//
// GetOp (cute.get)
//===----------------------------------------------------------------------===//

struct GetOpConversion final : public OpConversionPattern<GetOp> {
  using OpConversionPattern<GetOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    ArrayRef<int32_t> mode = adaptor.getMode().value_or(ArrayRef<int32_t>{});
    auto inputTy = op.getInput().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
        .Case<IntTupleType, ShapeType, StrideType, CoordType>([&](auto ty) {
          using TyClass = decltype(ty);
          using CgT = typename TyClass::algebra_t;
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(
              op, buildArithTuple(
                      b, cg::rec_var_cast<CgT>(cg::get(cgInput, mode))));
          return success();
        })
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op, buildLayout(b, cg::get(cgInput, mode)));
          return success();
        })
        .Case<TileType>([&](TileType) {
          auto cgInput = buildCutegenFromCuteValue<TileType>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op, buildTile(b, cg::get(cgInput, mode)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to ShapeType|IntTupleType|"
                           "CoordType|StrideType|TileType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// SelectOp (cute.select)
//===----------------------------------------------------------------------===//

struct SelectOpConversion final : public OpConversionPattern<SelectOp> {
  using OpConversionPattern<SelectOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SelectOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    ArrayRef<int32_t> mode = adaptor.getMode();
    auto inputTy = op.getInput().getType();
    return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
        .Case<IntTupleType, ShapeType, StrideType, CoordType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op, buildArithTuple(b, cg::select(cgInput, mode)));
          return success();
        })
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op, buildLayout(b, cg::select(cgInput, mode)));
          return success();
        })
        .Case<TileType>([&](TileType) {
          auto cgInput = buildCutegenFromCuteValue<TileType>(
              b, adaptor.getInput(), &listener);
          rewriter.replaceOp(op, buildTile(b, cg::select(cgInput, mode)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to ShapeType|IntTupleType|"
                           "CoordType|StrideType|TileType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// CompositionOp (cute.composition)
//===----------------------------------------------------------------------===//

struct CompositionOpConversion final
    : public OpConversionPattern<CompositionOp> {
  using OpConversionPattern<CompositionOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(CompositionOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto lhsTy = op.getLhs().getType();
    auto rhsTy = op.getRhs().getType();

    auto runRhs = [&](auto cgLhs) -> LogicalResult {
      return llvm::TypeSwitch<Type, LogicalResult>(rhsTy)
          .Case<LayoutType, ShapeType, TileType>([&](auto rhsTyClass) {
            using TyClass = decltype(rhsTyClass);
            auto cgRhs = buildCutegenFromCuteValue<TyClass>(b, adaptor.getRhs(),
                                                            &listener);
            auto res = cg::composition(cgLhs, cgRhs);
            rewriter.replaceOp(op, buildLayout(b, res));
            return success();
          })
          .Default([](Type) -> LogicalResult {
            llvm_unreachable("ODS constrains $rhs to "
                             "LayoutType|ShapeType|TileType");
          });
    };

    return llvm::TypeSwitch<Type, LogicalResult>(lhsTy)
        .Case<LayoutType>([&](LayoutType) {
          auto cgLhs = buildCutegenFromCuteValue<LayoutType>(
              b, adaptor.getLhs(), &listener);
          return runRhs(cgLhs);
        })
        .Case<ComposedLayoutType>([&](ComposedLayoutType) {
          auto cgLhs = buildCutegenFromCuteValue<ComposedLayoutType>(
              b, adaptor.getLhs(), &listener);
          return runRhs(cgLhs);
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $lhs to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// FlattenOp (cute.flatten)
//===----------------------------------------------------------------------===//

struct FlattenOpConversion final : public OpConversionPattern<FlattenOp> {
  using OpConversionPattern<FlattenOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(FlattenOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<ShapeType, StrideType, CoordType, IntTupleType, TileType,
              LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::flatten(cgInput);
          if constexpr (std::is_same_v<TyClass, ComposedLayoutType> ||
                        std::is_same_v<TyClass, LayoutType>) {
            rewriter.replaceOp(op, buildLayout(b, res));
          } else if constexpr (std::is_same_v<TyClass, TileType>) {
            rewriter.replaceOp(op, buildTile(b, res));
          } else {
            rewriter.replaceOp(op, buildArithTuple(b, res));
          }
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to ShapeType|StrideType|"
                           "CoordType|IntTupleType|TileType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// CoalesceOp (cute.coalesce)
//===----------------------------------------------------------------------===//

struct CoalesceOpConversion final : public OpConversionPattern<CoalesceOp> {
  using OpConversionPattern<CoalesceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(CoalesceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto getProfile = [&]() -> std::optional<cg::coord> {
      if (!adaptor.getTargetProfile()) {
        return std::nullopt;
      }
      return buildCutegenFromCuteValue<CoordType>(b, adaptor.getTargetProfile(),
                                                  &listener);
    };

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto profile = getProfile();
          auto res =
              profile ? cg::coalesce(cgInput, *profile) : cg::coalesce(cgInput);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// ComplementOp (cute.complement)
//===----------------------------------------------------------------------===//

struct ComplementOpConversion final : public OpConversionPattern<ComplementOp> {
  using OpConversionPattern<ComplementOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ComplementOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgInput =
        buildCutegenFromCuteValue<LayoutType>(b, adaptor.getInput(), &listener);

    // Dispatch on cotarget presence: absent -> cutegen's no-cotarget
    // overload complement(layout); present -> complement(layout, shape).
    auto cotargetVal = op.getCotarget();
    if (!cotargetVal) {
      auto res = cg::complement(cgInput);
      rewriter.replaceOp(op, buildLayout(b, res));
      return success();
    }
    return llvm::TypeSwitch<Type, LogicalResult>(cotargetVal.getType())
        .Case<ShapeType>([&](ShapeType) {
          auto cgCotarget = buildCutegenFromCuteValue<ShapeType>(
              b, adaptor.getCotarget(), &listener);
          auto res = cg::complement(cgInput, cgCotarget);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Case<LayoutType>([&](LayoutType) {
          auto cgCotarget = buildCutegenFromCuteValue<LayoutType>(
              b, adaptor.getCotarget(), &listener);
          auto res = cg::complement(cgInput, cgCotarget.shape());
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $cotarget to "
                           "Optional<LayoutType|ShapeType>");
        });
  }
};

//===----------------------------------------------------------------------===//
// GroupModesOp (cute.group_modes)
//===----------------------------------------------------------------------===//

struct GroupModesOpConversion final : public OpConversionPattern<GroupModesOp> {
  using OpConversionPattern<GroupModesOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GroupModesOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    int32_t begin = adaptor.getBegin();
    int32_t end = adaptor.getEnd();

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::group(begin, end, cgInput);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// RecastLayoutOp (cute.recast_layout)
//===----------------------------------------------------------------------===//

struct RecastLayoutOpConversion final
    : public OpConversionPattern<RecastLayoutOp> {
  using OpConversionPattern<RecastLayoutOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(RecastLayoutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getDst().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    int32_t newBits = adaptor.getNewTypeBits();
    int32_t oldBits = adaptor.getOldTypeBits();

    return llvm::TypeSwitch<Type, LogicalResult>(op.getSrc().getType())
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgSrc = buildCutegenFromCuteValue<TyClass>(b, adaptor.getSrc(),
                                                          &listener);
          auto res = cg::recast(newBits, oldBits, cgSrc);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// SliceOp (cute.slice)
//===----------------------------------------------------------------------===//

struct SliceOpConversion final : public OpConversionPattern<SliceOp> {
  using OpConversionPattern<SliceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SliceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgCoord =
        buildCutegenFromCuteValue<CoordType>(b, adaptor.getCoord(), &listener);

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<ShapeType, StrideType, IntTupleType, CoordType, LayoutType,
              ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::slice(cgCoord, cgInput);
          if constexpr (std::is_same_v<TyClass, ComposedLayoutType> ||
                        std::is_same_v<TyClass, LayoutType>) {
            rewriter.replaceOp(op, buildLayout(b, res));
          } else {
            rewriter.replaceOp(op, buildArithTuple(b, res));
          }
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to ShapeType|StrideType|"
                           "CoordType|IntTupleType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// DiceOp (cute.dice)
//===----------------------------------------------------------------------===//

struct DiceOpConversion final : public OpConversionPattern<DiceOp> {
  using OpConversionPattern<DiceOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(DiceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgCoord =
        buildCutegenFromCuteValue<CoordType>(b, adaptor.getCoord(), &listener);

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<ShapeType, StrideType, IntTupleType, CoordType, LayoutType,
              ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::dice(cgCoord, cgInput);
          if constexpr (std::is_same_v<TyClass, ComposedLayoutType> ||
                        std::is_same_v<TyClass, LayoutType>) {
            rewriter.replaceOp(op, buildLayout(b, res));
          } else {
            rewriter.replaceOp(op, buildArithTuple(b, res));
          }
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to ShapeType|StrideType|"
                           "CoordType|IntTupleType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

// right_inverse folds static results directly. Dynamic right_inverse results
// are rebuilt from runtime-bound cutegen values. left_inverse remains
// static-only.

template <typename OpTy>
struct InverseOpConversion final : public OpConversionPattern<OpTy> {
  using OpConversionPattern<OpTy>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(OpTy op, typename OpTy::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<LayoutType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }
    if constexpr (std::is_same_v<OpTy, RightInverseOp>) {
      cg::dynamic_listener listener(b);
      auto src = buildCutegenFromCuteValue<LayoutType>(
          b, adaptor.getInput(), &listener);
      auto res = cg::right_inverse(src);
      rewriter.replaceOp(op, buildLayout(b, res));
      return success();
    } else {
      return rewriter.notifyMatchFailure(
          op, "left_inverse requires a fully-static input");
    }
  }
};

//===----------------------------------------------------------------------===//
// RightInverseOp (cute.right_inverse)
//===----------------------------------------------------------------------===//

using RightInverseOpConversion = InverseOpConversion<RightInverseOp>;

//===----------------------------------------------------------------------===//
// LeftInverseOp (cute.left_inverse)
//===----------------------------------------------------------------------===//

using LeftInverseOpConversion = InverseOpConversion<LeftInverseOp>;

//===----------------------------------------------------------------------===//
// SizeIndex patterns
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// SizeOp (cute.size)
//===----------------------------------------------------------------------===//

struct SizeOpConversion final : public OpConversionPattern<SizeOp> {
  using OpConversionPattern<SizeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(SizeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    ArrayRef<int32_t> mode = adaptor.getMode().value_or(ArrayRef<int32_t>{});

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<ShapeType, IntTupleType, LayoutType, ComposedLayoutType>(
            [&](auto ty) {
              using TyClass = decltype(ty);
              auto cgInput = buildCutegenFromCuteValue<TyClass>(
                  b, adaptor.getInput(), &listener);
              auto res = cg::rec_var_cast<cg::int_tuple>(
                  cg::size(cg::get(cgInput, mode)));
              rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
              return success();
            })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "ShapeType|IntTupleType|LayoutType|"
                           "ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// CosizeOp (cute.cosize)
//===----------------------------------------------------------------------===//

struct CosizeOpConversion final : public OpConversionPattern<CosizeOp> {
  using OpConversionPattern<CosizeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(CosizeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    ArrayRef<int32_t> mode = adaptor.getMode().value_or(ArrayRef<int32_t>{});

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<LayoutType, ComposedLayoutType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::rec_var_cast<cg::int_tuple>(
              cg::cosize(cg::get(cgInput, mode)));
          rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// TupleProductOp (cute.tuple_product)
//===----------------------------------------------------------------------===//

struct TupleProductOpConversion final
    : public OpConversionPattern<TupleProductOp> {
  using OpConversionPattern<TupleProductOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(TupleProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<IntTupleType, ShapeType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::product(cgInput);
          rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "IntTupleType|ShapeType");
        });
  }
};

//===----------------------------------------------------------------------===//
// TupleProductEachOp (cute.tuple_product_each)
//===----------------------------------------------------------------------===//

struct TupleProductEachOpConversion final
    : public OpConversionPattern<TupleProductEachOp> {
  using OpConversionPattern<TupleProductEachOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(TupleProductEachOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
    if (staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<IntTupleType, ShapeType>([&](auto ty) {
          using TyClass = decltype(ty);
          auto cgInput = buildCutegenFromCuteValue<TyClass>(
              b, adaptor.getInput(), &listener);
          auto res = cg::product_each(cgInput);
          rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "IntTupleType|ShapeType");
        });
  }
};

//===----------------------------------------------------------------------===//
// LayoutEvalOp (cute.layout_eval)
//===----------------------------------------------------------------------===//

struct LayoutEvalOpConversion final : public OpConversionPattern<LayoutEvalOp> {
  using OpConversionPattern<LayoutEvalOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(LayoutEvalOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto coord =
        buildCutegenFromCuteValue<CoordType>(b, adaptor.getCoord(), &listener);

    cg::int_tuple res =
        llvm::TypeSwitch<Type, cg::int_tuple>(adaptor.getLayout().getType())
            .Case<LayoutType>([&](LayoutType) -> cg::int_tuple {
              auto layout = buildCutegenFromCuteValue<LayoutType>(
                  b, adaptor.getLayout(), &listener);
              return cg::layout_eval(coord, layout.shape(), layout.stride());
            })
            .Case<ComposedLayoutType>([&](ComposedLayoutType) -> cg::int_tuple {
              // Explicit 3-step decomposition:
              //   b_idx = layout_eval(coord, B.shape, B.stride)
              //   sum   = offset + b_idx
              //   res   = swizzle(sum)        (if A is a swizzle)
              //         | layout_eval(sum, A.shape, A.stride)  (if A is a
              //         layout)
              auto layout = buildCutegenFromCuteValue<ComposedLayoutType>(
                  b, adaptor.getLayout(), &listener);
              cg::int_tuple b_idx = cg::layout_eval(
                  coord, layout.layout_b().shape(), layout.layout_b().stride());
              if (!cg::is_valid(b_idx)) {
                return b_idx;
              }
              cg::int_tuple sum =
                  cg::arith_tuple_sum<cg::int_tuple>(layout.offset(), b_idx);
              if (!cg::is_valid(sum)) {
                return sum;
              }
              if (layout.is_a_swizzle()) {
                return layout.swizzle_a()(sum);
              }
              auto const &A = layout.layout_a();
              return cg::layout_eval(sum, A.shape(), A.stride());
            });

    if (cg::rank(res) == 0 && cg::depth(res) > 0) {
      res = cg::int_tuple(0);
    }
    rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Crd2IdxOp (cute.crd2idx)
//===----------------------------------------------------------------------===//

struct Crd2IdxOpConversion final : public OpConversionPattern<Crd2IdxOp> {
  using OpConversionPattern<Crd2IdxOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(Crd2IdxOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<IntTupleType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto coord =
        buildCutegenFromCuteValue<CoordType>(b, adaptor.getCoord(), &listener);
    auto shape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);
    cg::int_tuple res = cg::crd2idx(coord, shape);
    rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Idx2CrdOp (cute.idx2crd)
//===----------------------------------------------------------------------===//

struct Idx2CrdOpConversion final : public OpConversionPattern<Idx2CrdOp> {
  using OpConversionPattern<Idx2CrdOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(Idx2CrdOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<CoordType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto idx = buildCutegenFromCuteValue<IntTupleType>(b, adaptor.getIndex(),
                                                       &listener);
    auto shape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);
    auto res = cg::rec_var_cast<cg::coord>(cg::idx2crd(idx, shape));
    rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// IncrementCoordOp (cute.increment_coord)
//===----------------------------------------------------------------------===//

struct IncrementCoordOpConversion final
    : public OpConversionPattern<IncrementCoordOp> {
  using OpConversionPattern<IncrementCoordOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(IncrementCoordOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<CoordType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto coord =
        buildCutegenFromCuteValue<CoordType>(b, adaptor.getCoord(), &listener);
    auto shape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);
    auto res = cg::rec_var_cast<cg::coord>(cg::increment_coord(coord, shape));
    rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
    return success();
  }
};

/// Shared lowering for cute.append_to_rank / cute.prepend_to_rank.
/// IsAppend selects the cutegen function and the diagnostic noun; the
/// rest of the conversion is identical across the two ops.
template <bool IsAppend, typename Op, typename OpAdaptor>
LogicalResult expandXToRank(Op op, OpAdaptor adaptor,
                            ConversionPatternRewriter &rewriter) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  auto resTy = op.getResult().getType();
  auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
  if (staticInterface && staticInterface.isStatic()) {
    rewriter.replaceOp(op, StaticOp::create(b, resTy));
    return success();
  }

  cg::dynamic_listener listener(b);
  int32_t rank = adaptor.getRank();

  return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
      .template Case<IntTupleType, CoordType, StrideType, ShapeType, LayoutType,
                     ComposedLayoutType>([&](auto ty) {
        using TyClass = decltype(ty);
        // For composed_layout input, the element is a plain layout; otherwise
        // element is the same kind as input.
        using ElemTy =
            std::conditional_t<std::is_same_v<TyClass, ComposedLayoutType>,
                               LayoutType, TyClass>;
        auto cgInput = buildCutegenFromCuteValue<TyClass>(b, adaptor.getInput(),
                                                          &listener);
        auto cgElement = buildCutegenFromCuteValue<ElemTy>(
            b, adaptor.getElement(), &listener);
        auto res = IsAppend ? cg::append_to_rank_N(rank, cgInput, cgElement)
                            : cg::prepend_to_rank_N(rank, cgInput, cgElement);
        if constexpr (std::is_same_v<TyClass, ComposedLayoutType> ||
                      std::is_same_v<TyClass, LayoutType>) {
          rewriter.replaceOp(op, buildLayout(b, res));
        } else {
          rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
        }
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to IntTupleType|CoordType|"
                         "StrideType|ShapeType|LayoutType|"
                         "ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// AppendToRankOp (cute.append_to_rank)
//===----------------------------------------------------------------------===//

struct AppendToRankOpConversion final
    : public OpConversionPattern<AppendToRankOp> {
  using OpConversionPattern<AppendToRankOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(AppendToRankOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandXToRank</*IsAppend=*/true>(op, adaptor, rewriter);
  }
};

//===----------------------------------------------------------------------===//
// PrependToRankOp (cute.prepend_to_rank)
//===----------------------------------------------------------------------===//

struct PrependToRankOpConversion final
    : public OpConversionPattern<PrependToRankOp> {
  using OpConversionPattern<PrependToRankOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(PrependToRankOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandXToRank</*IsAppend=*/false>(op, adaptor, rewriter);
  }
};

//===----------------------------------------------------------------------===//
// Arithmetic patterns
//===----------------------------------------------------------------------===//

/// Common helper for the two tuple-arith ops (`tuple_add`, `tuple_sub`).
/// Both share an identical body modulo the cutegen function pointer;
/// the only kind constraint is that `lhs` and `rhs` are the same kind
/// (`int_tuple` or `shape`), enforced inside each op's `inferReturnTypes`.
template <typename Op, typename CallFn>
LogicalResult expandTupleArith(Op op, typename Op::Adaptor adaptor,
                               ConversionPatternRewriter &rewriter,
                               CallFn callFn) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  auto resTy = op.getResult().getType();
  if (auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
      staticInterface && staticInterface.isStatic()) {
    rewriter.replaceOp(op, StaticOp::create(b, resTy));
    return success();
  }

  cg::dynamic_listener listener(b);
  return llvm::TypeSwitch<Type, LogicalResult>(op.getLhs().getType())
      .template Case<IntTupleType, ShapeType>([&](auto ty) {
        using TyClass = decltype(ty);
        auto cgLhs =
            buildCutegenFromCuteValue<TyClass>(b, adaptor.getLhs(), &listener);
        auto cgRhs =
            buildCutegenFromCuteValue<TyClass>(b, adaptor.getRhs(), &listener);
        auto res = callFn(cgLhs, cgRhs);
        rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to IntTupleType|ShapeType");
      });
}

//===----------------------------------------------------------------------===//
// TupleAddOp (cute.tuple_add)
//===----------------------------------------------------------------------===//

struct TupleAddOpConversion final : public OpConversionPattern<TupleAddOp> {
  using OpConversionPattern<TupleAddOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(TupleAddOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandTupleArith(op, adaptor, rewriter, [](auto &lhs, auto &rhs) {
      using T = std::decay_t<decltype(lhs)>;
      return cg::arith_tuple_sum<T>(lhs, rhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// TupleSubOp (cute.tuple_sub)
//===----------------------------------------------------------------------===//

struct TupleSubOpConversion final : public OpConversionPattern<TupleSubOp> {
  using OpConversionPattern<TupleSubOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(TupleSubOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandTupleArith(op, adaptor, rewriter, [](auto &lhs, auto &rhs) {
      using T = std::decay_t<decltype(lhs)>;
      return cg::arith_tuple_sub<T>(lhs, rhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// ShapeDivOp (cute.shape_div)
//===----------------------------------------------------------------------===//

struct ShapeDivOpConversion final : public OpConversionPattern<ShapeDivOp> {
  using OpConversionPattern<ShapeDivOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ShapeDivOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = llvm::cast<ShapeType>(op.getResult().getType());
    if (cg::is_static(resTy.getRef())) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto shapeA =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getA(), &listener);
    auto shapeB =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getB(), &listener);
    auto res = cg::shape_div(shapeA, shapeB);
    rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// CeilDivOp (cute.ceil_div)
//===----------------------------------------------------------------------===//

struct CeilDivOpConversion final : public OpConversionPattern<CeilDivOp> {
  using OpConversionPattern<CeilDivOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(CeilDivOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    if (auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
        staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    // CeilDivOp result kind always matches input kind (per ODS); tiler kind
    // is independent and dispatched via its own TypeSwitch.
    //

    // cg::ceil_div(int_tuple, tile) does not have a defined cutegen
    // overload (its scalar_ceil_div_visitor doesn't cover the
    // layout_t / underscore_t alternatives inside cute_tile_t).
    // Bridge through shape when input is int_tuple and tiler is tile.
    cg::dynamic_listener listener(b);
    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<IntTupleType, ShapeType>([&](auto inputTy) {
          using InputClass = decltype(inputTy);
          auto cgInput = buildCutegenFromCuteValue<InputClass>(
              b, adaptor.getInput(), &listener);
          return llvm::TypeSwitch<Type, LogicalResult>(op.getTiler().getType())
              .template Case<IntTupleType, ShapeType>([&](auto tilerTy) {
                using TilerClass = decltype(tilerTy);
                auto cgTiler = buildCutegenFromCuteValue<TilerClass>(
                    b, adaptor.getTiler(), &listener);
                auto res = cg::ceil_div(cgInput, cgTiler);
                rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
                return success();
              })
              .template Case<TileType>([&](TileType) {
                auto cgTiler = buildCutegenFromCuteValue<TileType>(
                    b, adaptor.getTiler(), &listener);
                // Bridge int_tuple input to shape so cutegen's
                // ceil_div(shape, tile) overload is selected.
                auto cgInputShape =
                    cg::rec_var_cast<cg::shape>(std::move(cgInput));
                auto res = cg::ceil_div(cgInputShape, cgTiler);
                if constexpr (std::is_same_v<InputClass, IntTupleType>) {
                  rewriter.replaceOp(
                      op,
                      buildArithTuple(b, cg::rec_var_cast<cg::int_tuple>(res)));
                } else {
                  rewriter.replaceOp(op, buildArithTuple(b, std::move(res)));
                }
                return success();
              })
              .Default([](Type) -> LogicalResult {
                llvm_unreachable("ODS constrains $tiler to "
                                 "IntTupleType|ShapeType|TileType");
              });
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "IntTupleType|ShapeType");
        });
  }
};

/// Shared expansion for elem_less and equal: extract every integer
/// leaf from each side via cute.get_scalars and AND a chain of per-leaf
/// arith.cmpi <pred> results. Static leaves come back as i64 integer
/// constants; cutegen's get_compare_value<pred> handles per-leaf width
/// promotion when the two sides differ. The AND chain is seeded from the
/// first comparison (N× cmpi + (N-1)× andi).
template <typename Op, cg::comp_pred Pred>
LogicalResult expandLeafCompare(Op op, typename Op::Adaptor adaptor,
                                ConversionPatternRewriter &rewriter,
                                StringRef opName) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  ValueRange lhsVal =
      GetScalarsOp::create(b, adaptor.getLhs(), /*only_dynamic=*/nullptr)
          .getScalars();
  ValueRange rhsVal =
      GetScalarsOp::create(b, adaptor.getRhs(), /*only_dynamic=*/nullptr)
          .getScalars();
  if (lhsVal.size() != rhsVal.size()) {
    return rewriter.notifyMatchFailure(
        op, opName.str() + ": lhs/rhs leaf counts disagree");
  }
  if (lhsVal.empty()) {
    return rewriter.notifyMatchFailure(op,
                                       opName.str() + ": no leaves to compare");
  }

  Type i1Ty = b.getI1Type();
  cg::dynamic_listener listener(b);

  cg::mlir_dynamic_t firstLhs{lhsVal[0], &listener};
  cg::mlir_dynamic_t firstRhs{rhsVal[0], &listener};
  Value resVal = cg::get_compare_value<Pred>(firstLhs, firstRhs);

  for (size_t i = 1; i < lhsVal.size(); ++i) {
    cg::mlir_dynamic_t lhsLeaf{lhsVal[i], &listener};
    cg::mlir_dynamic_t rhsLeaf{rhsVal[i], &listener};
    Value cmp = cg::get_compare_value<Pred>(lhsLeaf, rhsLeaf);
    resVal = arith::AndIOp::create(b, i1Ty, resVal, cmp);
  }
  rewriter.replaceOp(op, resVal);
  return success();
}

//===----------------------------------------------------------------------===//
// ElemLessOp (cute.elem_less)
//===----------------------------------------------------------------------===//

struct ElemLessOpConversion final : public OpConversionPattern<ElemLessOp> {
  using OpConversionPattern<ElemLessOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(ElemLessOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (bothOperandsStatic(op) &&
        succeeded(tryStaticFoldElemLess(op, rewriter))) {
      return success();
    }
    return expandLeafCompare<ElemLessOp, cg::comp_pred::lt>(
        op, adaptor, rewriter, "elem_less");
  }
};

//===----------------------------------------------------------------------===//
// EqualOp (cute.equal)
//===----------------------------------------------------------------------===//

struct EqualOpConversion final : public OpConversionPattern<EqualOp> {
  using OpConversionPattern<EqualOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(EqualOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    // Operand kinds are restricted by ODS via Cute_EqualOperandType
    // ({IntTuple, Shape, Coord, Stride, Layout}); same-kind by the
    // verifier. For Layout, get_scalars emits shape-then-stride
    // leaves on each side — ANDing the per-leaf eq comparisons is
    // exactly the structural equality for layouts that already share
    // a static type signature.
    if (bothOperandsStatic(op)) {
      return tryStaticFoldEqual(op, rewriter);
    }
    return expandLeafCompare<EqualOp, cg::comp_pred::eq>(op, adaptor, rewriter,
                                                         "equal");
  }
};

//===----------------------------------------------------------------------===//
// TilingPartitioningProducts patterns
//===----------------------------------------------------------------------===//

/// Product-family expansion shape: lhs may be Layout or
/// ComposedLayout; rhs is always a plain Layout. Result kind matches
/// lhs kind. prodFn is a generic lambda (cgLhs, cgRhs) -> auto.
template <typename Op, typename ProdFn>
LogicalResult expandProductOp(Op op, typename Op::Adaptor adaptor,
                              ConversionPatternRewriter &rewriter,
                              ProdFn prodFn) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  auto resTy = op.getResult().getType();
  if (auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
      staticInterface && staticInterface.isStatic()) {
    rewriter.replaceOp(op, StaticOp::create(b, resTy));
    return success();
  }

  cg::dynamic_listener listener(b);
  auto cgRhs =
      buildCutegenFromCuteValue<LayoutType>(b, adaptor.getRhs(), &listener);
  return llvm::TypeSwitch<Type, LogicalResult>(op.getLhs().getType())
      .template Case<LayoutType, ComposedLayoutType>([&](auto lhsTy) {
        using LhsClass = decltype(lhsTy);
        auto cgLhs =
            buildCutegenFromCuteValue<LhsClass>(b, adaptor.getLhs(), &listener);
        auto res = prodFn(cgLhs, cgRhs);
        rewriter.replaceOp(op, buildLayout(b, res));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to "
                         "LayoutType|ComposedLayoutType");
      });
}

/// Divide-family expansion shape: input is Layout or ComposedLayout;
/// tiler is Layout, Tile, or Shape. Result kind matches input kind.
/// divFn is a generic lambda (cgInput, cgTiler) -> auto.
template <typename Op, typename DivFn>
LogicalResult expandDivideOp(Op op, typename Op::Adaptor adaptor,
                             ConversionPatternRewriter &rewriter, DivFn divFn) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  auto resTy = op.getResult().getType();
  if (auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
      staticInterface && staticInterface.isStatic()) {
    rewriter.replaceOp(op, StaticOp::create(b, resTy));
    return success();
  }

  cg::dynamic_listener listener(b);
  Type tilerTy = op.getTiler().getType();
  auto callWithTiler = [&](auto cgInput) {
    if (llvm::isa<LayoutType>(tilerTy)) {
      auto cgT = buildCutegenFromCuteValue<LayoutType>(b, adaptor.getTiler(),
                                                       &listener);
      return divFn(cgInput, cgT);
    }
    if (llvm::isa<TileType>(tilerTy)) {
      auto cgT =
          buildCutegenFromCuteValue<TileType>(b, adaptor.getTiler(), &listener);
      return divFn(cgInput, cgT);
    }
    auto cgT =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getTiler(), &listener);
    return divFn(cgInput, cgT);
  };

  return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
      .template Case<LayoutType, ComposedLayoutType>([&](auto inputTy) {
        using InputClass = decltype(inputTy);
        auto cgInput = buildCutegenFromCuteValue<InputClass>(
            b, adaptor.getInput(), &listener);
        auto res = callWithTiler(cgInput);
        rewriter.replaceOp(op, buildLayout(b, res));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// LogicalProductOp (cute.logical_product)
//===----------------------------------------------------------------------===//

struct LogicalProductOpConversion final
    : public OpConversionPattern<LogicalProductOp> {
  using OpConversionPattern<LogicalProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(LogicalProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::logical_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// ZippedProductOp (cute.zipped_product)
//===----------------------------------------------------------------------===//

struct ZippedProductOpConversion final
    : public OpConversionPattern<ZippedProductOp> {
  using OpConversionPattern<ZippedProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(ZippedProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::zipped_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// TiledProductOp (cute.tiled_product)
//===----------------------------------------------------------------------===//

struct TiledProductOpConversion final
    : public OpConversionPattern<TiledProductOp> {
  using OpConversionPattern<TiledProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(TiledProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::tiled_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// FlatProductOp (cute.flat_product)
//===----------------------------------------------------------------------===//

struct FlatProductOpConversion final
    : public OpConversionPattern<FlatProductOp> {
  using OpConversionPattern<FlatProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(FlatProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::flat_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// RakedProductOp (cute.raked_product)
//===----------------------------------------------------------------------===//

struct RakedProductOpConversion final
    : public OpConversionPattern<RakedProductOp> {
  using OpConversionPattern<RakedProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(RakedProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::raked_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// BlockedProductOp (cute.blocked_product)
//===----------------------------------------------------------------------===//

struct BlockedProductOpConversion final
    : public OpConversionPattern<BlockedProductOp> {
  using OpConversionPattern<BlockedProductOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(BlockedProductOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandProductOp(op, adaptor, rewriter, [](auto &cgLhs, auto &cgRhs) {
      return cg::blocked_product(cgLhs, cgRhs);
    });
  }
};

//===----------------------------------------------------------------------===//
// LogicalDivideOp (cute.logical_divide)
//===----------------------------------------------------------------------===//

struct LogicalDivideOpConversion final
    : public OpConversionPattern<LogicalDivideOp> {
  using OpConversionPattern<LogicalDivideOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(LogicalDivideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandDivideOp(op, adaptor, rewriter,
                          [](auto &cgInput, auto &cgTiler) {
                            return cg::logical_divide(cgInput, cgTiler);
                          });
  }
};

//===----------------------------------------------------------------------===//
// ZippedDivideOp (cute.zipped_divide)
//===----------------------------------------------------------------------===//

struct ZippedDivideOpConversion final
    : public OpConversionPattern<ZippedDivideOp> {
  using OpConversionPattern<ZippedDivideOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(ZippedDivideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandDivideOp(op, adaptor, rewriter,
                          [](auto &cgInput, auto &cgTiler) {
                            return cg::zipped_divide(cgInput, cgTiler);
                          });
  }
};

//===----------------------------------------------------------------------===//
// TiledDivideOp (cute.tiled_divide)
//===----------------------------------------------------------------------===//

struct TiledDivideOpConversion final
    : public OpConversionPattern<TiledDivideOp> {
  using OpConversionPattern<TiledDivideOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(TiledDivideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandDivideOp(op, adaptor, rewriter,
                          [](auto &cgInput, auto &cgTiler) {
                            return cg::tiled_divide(cgInput, cgTiler);
                          });
  }
};

//===----------------------------------------------------------------------===//
// FlatDivideOp (cute.flat_divide)
//===----------------------------------------------------------------------===//

struct FlatDivideOpConversion final : public OpConversionPattern<FlatDivideOp> {
  using OpConversionPattern<FlatDivideOp>::OpConversionPattern;
  LogicalResult
  matchAndRewrite(FlatDivideOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    return expandDivideOp(op, adaptor, rewriter,
                          [](auto &cgInput, auto &cgTiler) {
                            return cg::flat_divide(cgInput, cgTiler);
                          });
  }
};

//===----------------------------------------------------------------------===//
// TileToShapeOp (cute.tile_to_shape)
//===----------------------------------------------------------------------===//

struct TileToShapeOpConversion final
    : public OpConversionPattern<TileToShapeOp> {
  using OpConversionPattern<TileToShapeOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(TileToShapeOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    ImplicitLocOpBuilder b(op.getLoc(), rewriter);
    auto resTy = op.getResult().getType();
    if (auto staticInterface = llvm::dyn_cast<MaybeStaticTypeInterface>(resTy);
        staticInterface && staticInterface.isStatic()) {
      rewriter.replaceOp(op, StaticOp::create(b, resTy));
      return success();
    }

    cg::dynamic_listener listener(b);
    auto cgShape =
        buildCutegenFromCuteValue<ShapeType>(b, adaptor.getShape(), &listener);

    // Optional $order operand. Always static per ODS / inferReturnTypes;
    // pull the cutegen ref directly off the type without going through
    // buildCutegen.
    const cg::int_tuple *orderRef = nullptr;
    if (Value orderVal = adaptor.getOrder()) {
      orderRef = &llvm::cast<IntTupleType>(orderVal.getType()).getRef();
    }

    return llvm::TypeSwitch<Type, LogicalResult>(op.getInput().getType())
        .Case<LayoutType, ComposedLayoutType>([&](auto inputTy) {
          using InputClass = decltype(inputTy);
          auto cgInput = buildCutegenFromCuteValue<InputClass>(
              b, adaptor.getInput(), &listener);
          auto res = orderRef ? cg::tile_to_shape(cgInput, cgShape, *orderRef)
                              : cg::tile_to_shape(cgInput, cgShape);
          rewriter.replaceOp(op, buildLayout(b, res));
          return success();
        })
        .Default([](Type) -> LogicalResult {
          llvm_unreachable("ODS constrains $input to "
                           "LayoutType|ComposedLayoutType");
        });
  }
};

//===----------------------------------------------------------------------===//
// Pass driver
//===----------------------------------------------------------------------===//

struct CuteExpandOpsPass
    : public mlir::cutlass_compiler::cute::impl::CuteExpandOpsBase<
          CuteExpandOpsPass> {
  void runOnOperation() override {
    MLIRContext &context = getContext();

    // Identity TypeConverter — patterns rewrite ops, not types. The framework
    // still requires a converter for OpConversionPattern to receive remapped
    // operands; the source/target materializers create
    // unrealized_conversion_cast for any type bridge that survives. Stale
    // casts are cleaned up by a downstream reconcile-unrealized-casts run.
    TypeConverter typeConverter;
    typeConverter.addConversion([](Type ty) { return ty; });
    auto materialize = [](OpBuilder &builder, Type resultType,
                          ValueRange inputs, Location loc) -> Value {
      return UnrealizedConversionCastOp::create(builder, loc, resultType,
                                                inputs)
          .getResult(0);
    };
    typeConverter.addSourceMaterialization(materialize);
    typeConverter.addTargetMaterialization(materialize);

    ConversionTarget target(context);
    target.addLegalDialect<arith::ArithDialect, math::MathDialect,
                           scf::SCFDialect, CuteDialect>();
    target.addIllegalOp<
        // AdvancedConstructors
        MakeLayoutLikeOp, MakeOrderedLayoutOp, MakeIdentityLayoutOp,
        // Accessors
        GetShapeOp, GetStrideOp, ComposedGetInnerOp, ComposedGetOffsetOp,
        ComposedGetOuterOp, ToIntTupleOp, ToShapeOp, ToStrideOp, ToCoordOp,
        GetLayoutsFromTileOp, GetLeavesOp, GetOp, SelectOp,
        // LayoutAlgebra
        CompositionOp, CoalesceOp, ComplementOp, FlattenOp, GroupModesOp,
        RecastLayoutOp, SliceOp, DiceOp, RightInverseOp, LeftInverseOp,
        // SizeIndex
        SizeOp, CosizeOp, TupleProductOp, TupleProductEachOp, Crd2IdxOp,
        LayoutEvalOp, Idx2CrdOp, IncrementCoordOp, AppendToRankOp,
        PrependToRankOp,
        // Arithmetic
        TupleAddOp, TupleSubOp, ShapeDivOp, CeilDivOp, ElemLessOp, EqualOp,
        // TilingPartitioningProducts
        LogicalProductOp, ZippedProductOp, TiledProductOp, FlatProductOp,
        RakedProductOp, BlockedProductOp, LogicalDivideOp, ZippedDivideOp,
        TiledDivideOp, FlatDivideOp, TileToShapeOp>();
    target.markUnknownOpDynamicallyLegal([](Operation *op) {
      return !isa<
          // AdvancedConstructors
          MakeLayoutLikeOp, MakeOrderedLayoutOp, MakeIdentityLayoutOp,
          // Accessors
          GetShapeOp, GetStrideOp, ComposedGetInnerOp, ComposedGetOffsetOp,
          ComposedGetOuterOp, ToIntTupleOp, ToShapeOp, ToStrideOp, ToCoordOp,
          GetLayoutsFromTileOp, GetLeavesOp, GetOp, SelectOp,
          // LayoutAlgebra
          CompositionOp, CoalesceOp, ComplementOp, FlattenOp, GroupModesOp,
          RecastLayoutOp, SliceOp, DiceOp, RightInverseOp, LeftInverseOp,
          // SizeIndex
          SizeOp, CosizeOp, TupleProductOp, TupleProductEachOp, LayoutEvalOp,
          Idx2CrdOp, IncrementCoordOp, AppendToRankOp, PrependToRankOp,
          // Arithmetic
          TupleAddOp, TupleSubOp, ShapeDivOp, CeilDivOp, ElemLessOp, EqualOp,
          // TilingPartitioningProducts
          LogicalProductOp, ZippedProductOp, TiledProductOp, FlatProductOp,
          RakedProductOp, BlockedProductOp, LogicalDivideOp, ZippedDivideOp,
          TiledDivideOp, FlatDivideOp, TileToShapeOp>(op);
    });

    RewritePatternSet patterns(&context);
    patterns.add<
        // AdvancedConstructors
        MakeLayoutLikeOpConversion, MakeOrderedLayoutOpConversion,
        MakeIdentityLayoutOpConversion,
        // Accessors
        GetShapeOpConversion, GetStrideOpConversion,
        ComposedGetInnerOpConversion, ComposedGetOffsetOpConversion,
        ComposedGetOuterOpConversion, ToIntTupleOpConversion,
        ToShapeOpConversion, ToStrideOpConversion, ToCoordOpConversion,
        GetLayoutsFromTileOpConversion, GetLeavesOpConversion, GetOpConversion,
        SelectOpConversion,
        // LayoutAlgebra
        CompositionOpConversion, CoalesceOpConversion, ComplementOpConversion,
        FlattenOpConversion, GroupModesOpConversion, RecastLayoutOpConversion,
        SliceOpConversion, DiceOpConversion, RightInverseOpConversion,
        LeftInverseOpConversion,
        // SizeIndex
        SizeOpConversion, CosizeOpConversion, TupleProductOpConversion,
        TupleProductEachOpConversion, Crd2IdxOpConversion,
        LayoutEvalOpConversion, Idx2CrdOpConversion, IncrementCoordOpConversion,
        AppendToRankOpConversion, PrependToRankOpConversion,
        // Arithmetic
        TupleAddOpConversion, TupleSubOpConversion, ShapeDivOpConversion,
        CeilDivOpConversion, ElemLessOpConversion, EqualOpConversion,
        // TilingPartitioningProducts
        LogicalProductOpConversion, ZippedProductOpConversion,
        TiledProductOpConversion, FlatProductOpConversion,
        RakedProductOpConversion, BlockedProductOpConversion,
        LogicalDivideOpConversion, ZippedDivideOpConversion,
        TiledDivideOpConversion, FlatDivideOpConversion,
        TileToShapeOpConversion>(typeConverter, &context);

    if (failed(applyPartialConversion(getOperation(), target,
                                      std::move(patterns)))) {
      signalPassFailure();
    }
  }
};

} // namespace
