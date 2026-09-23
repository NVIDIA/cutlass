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

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;

namespace cg = cutegen;

//===----------------------------------------------------------------------===//
// Decay helper
//===----------------------------------------------------------------------===//

/// True if type is fully static and every leaf is non-zero.
template <typename TyClass>
static bool isStaticAllLeavesNonZero(TyClass type) {
  const auto &ref = type.getRef();
  if (!cg::is_static(ref)) {
    return false;
  }
  return cg::all_leaves(ref, [](const auto &leaf) {
    return cg::holds_int(leaf) && leaf.as_int64() != 0;
  });
}

/// Pick the result type for cute.op(composed_layout, ...) -> composed_layout
/// patterns: decay to LayoutType when the computed composed layout is
/// is_normal_layout(); otherwise track the input kind.
template <class TyClass, class CgResult>
static mlir::Type pickNormalOrComposedLayoutType(MLIRContext *context,
                                                 CgResult res) {
  if constexpr (std::is_same_v<TyClass, ComposedLayoutType>) {
    if (res.is_normal_layout()) {
      return LayoutType::get(context, res.layout_b());
    }
  }
  return TyClass::get(context, std::move(res));
}

//===----------------------------------------------------------------------===//
// StaticOp (cute.static)
//===----------------------------------------------------------------------===//

LogicalResult StaticOp::verify() {
  if (!getType().isStatic()) {
    return emitOpError() << "expects result to be static, but got "
                         << getType();
  }
  return success();
}

/// Required by the `ConstantLike` trait: every `ConstantLike` op must fold
/// into a non-null `Attribute` (MLIR's `m_Constant` matcher asserts on this).
/// `cute.static`'s value lives entirely in its result type, so we delegate
/// to `MaybeStaticTypeInterface::getValueAttr()`, which returns the type's
/// payload attribute (e.g. `ShapeAttr`, `LayoutAttr`).
OpFoldResult StaticOp::fold(FoldAdaptor /*adaptor*/) {
  return llvm::cast<MaybeStaticTypeInterface>(getType()).getValueAttr();
}

//===----------------------------------------------------------------------===//
// Shared verifier for scalar-tuple constructor ops
// (MakeIntTupleOp, MakeShapeOp, MakeStrideOp, MakeCoordOp)
//===----------------------------------------------------------------------===//

/// TupleTy is the CuteIR tuple type accepted as a nested sub-tuple operand
/// (e.g. IntTupleType for MakeIntTupleOp). Its rank must be 1 — passing a
/// multi-element tuple as a single operand slot is rejected.
template <typename OpTy, typename TupleTy>
static LogicalResult verifyMakeScalarTupleOp(OpTy op) {
  using int_properties_t = cg::dynamic_int_properties_t;

  SmallVector<cg::dynamic_t> resDynVals;
  cg::collect_dynamics(resDynVals, op.getResult().getType().getRef());
  auto numOperands = static_cast<size_t>(op.getOperands().size());
  if (resDynVals.size() != numOperands) {
    return op.emitOpError("expects ")
           << resDynVals.size() << " dynamic operand(s) for result type "
           << op.getResult().getType() << ", but got " << numOperands;
  }

  for (auto i : llvm::seq<int>(resDynVals.size())) {
    int_properties_t operandProp{};
    const int_properties_t &resProp = resDynVals[i].get_properties();
    auto ty = op.getOperands()[i].getType();
    if (auto tupleTy = llvm::dyn_cast<IntTupleType>(ty)) {
      auto &tupleRef = tupleTy.getRef();
      if (cg::holds_int(tupleRef)) {
        if (!resProp.are_compatible(tupleRef.as_int())) {
          return op.emitOpError("expects operand #")
                 << i << " to be compatible with (width=" << resProp.width
                 << "), but got static constant " << tupleRef.as_int();
        }
        continue;
      }
      operandProp = std::get<cg::mlir_dynamic_t>(tupleRef).get_properties();
    } else if (auto intTy = llvm::dyn_cast<IntegerType>(ty)) {
      operandProp.width = intTy.getWidth();
    }
    if (operandProp.width != resProp.width) {
      return op.emitOpError("expects operand #")
             << i << " to have (width=" << resProp.width
             << "), but got (width=" << operandProp.width << ")";
    }
  }

  return success();
}

//===----------------------------------------------------------------------===//
// MakeIntTupleOp (cute.make_int_tuple)
//===----------------------------------------------------------------------===//

LogicalResult MakeIntTupleOp::verify() {
  return verifyMakeScalarTupleOp<MakeIntTupleOp, IntTupleType>(*this);
}

//===----------------------------------------------------------------------===//
// MakeShapeOp (cute.make_shape)
//===----------------------------------------------------------------------===//

LogicalResult MakeShapeOp::verify() {
  return verifyMakeScalarTupleOp<MakeShapeOp, IntTupleType>(*this);
}

//===----------------------------------------------------------------------===//
// MakeStrideOp (cute.make_stride)
//===----------------------------------------------------------------------===//

LogicalResult MakeStrideOp::verify() {
  return verifyMakeScalarTupleOp<MakeStrideOp, IntTupleType>(*this);
}

//===----------------------------------------------------------------------===//
// MakeCoordOp (cute.make_coord)
//===----------------------------------------------------------------------===//

LogicalResult MakeCoordOp::verify() {
  return verifyMakeScalarTupleOp<MakeCoordOp, IntTupleType>(*this);
}

//===----------------------------------------------------------------------===//
// MakeLayoutOp (cute.make_layout)
//===----------------------------------------------------------------------===//

LogicalResult MakeLayoutOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);

  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }
  auto strideTy = llvm::dyn_cast<StrideType>(adaptor.getStride().getType());
  if (!strideTy) {
    return emitOptionalError(location,
                             "expects stride to be !cute.stride, but got ",
                             adaptor.getStride().getType());
  }

  inferredReturnTypes.push_back(LayoutType::get(
      context, cg::layout(shapeTy.getRef(), strideTy.getRef())));
  return success();
}

//===----------------------------------------------------------------------===//
// MakeTileOp (cute.make_tile)
//===----------------------------------------------------------------------===//

LogicalResult MakeTileOp::verify() {
  return verifyMakeScalarTupleOp<MakeTileOp, IntTupleType>(*this);
}

//===----------------------------------------------------------------------===//
// MakeComposedLayoutOp (cute.make_composed_layout)
//===----------------------------------------------------------------------===//

LogicalResult MakeComposedLayoutOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);

  auto offsetTy = llvm::dyn_cast<IntTupleType>(adaptor.getOffset().getType());
  if (!offsetTy) {
    return emitOptionalError(location,
                             "expects offset to be !cute.int_tuple, "
                             "but got ",
                             adaptor.getOffset().getType());
  }

  auto outerTy = llvm::dyn_cast<LayoutType>(adaptor.getOuter().getType());
  if (!outerTy) {
    return emitOptionalError(location,
                             "expects outer to be !cute.layout, "
                             "but got ",
                             adaptor.getOuter().getType());
  }

  auto push = [&](auto ref) {
    inferredReturnTypes.push_back(
        ComposedLayoutType::get(context, std::move(ref)));
  };
  auto innerTy = adaptor.getInner().getType();
  if (auto layoutTy = llvm::dyn_cast<LayoutType>(innerTy)) {
    push(cg::composed_layout(layoutTy.getRef(), offsetTy.getRef(),
                             outerTy.getRef()));
    return success();
  }
  if (auto swizzleTy = llvm::dyn_cast<SwizzleType>(innerTy)) {
    push(cg::composed_layout(swizzleTy.getRef(), offsetTy.getRef(),
                             outerTy.getRef()));
    return success();
  }
  return emitOptionalError(location,
                           "expects inner to be !cute.layout or !cute.swizzle, "
                           "but got ",
                           innerTy);
}

//===----------------------------------------------------------------------===//
// MakeLayoutLikeOp (cute.make_layout_like)
//===----------------------------------------------------------------------===//

LogicalResult MakeLayoutLikeOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);

  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getSrc().getType())
      .Case<LayoutType>([&](LayoutType ty) -> LogicalResult {
        if (cg::has_scaled_basis(ty.getRef().stride())) {
          return emitOptionalError(
              location, "expects plain integer strides in source layout,"
                        " but got scaled-basis strides");
        }
        cg::layout res = cg::make_layout_like(ty.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects a valid layout-like result, but"
                                   " construction failed");
        }
        inferredReturnTypes.push_back(LayoutType::get(context, std::move(res)));
        return success();
      })
      .Case<ComposedLayoutType>([&](ComposedLayoutType ty) -> LogicalResult {
        if (!ty.getRef().is_a_swizzle()) {
          return emitOptionalError(
              location, "expects source composed layout to have a Swizzle A"
                        " component, but got a layout A");
        }
        if (cg::has_scaled_basis(ty.getRef().layout_b().stride())) {
          return emitOptionalError(
              location, "expects plain integer strides in outer B layout of"
                        " composed source, but got scaled-basis strides");
        }
        cg::layout res = cg::make_layout_like(ty.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects a valid layout-like result, but"
                                   " construction failed");
        }
        inferredReturnTypes.push_back(LayoutType::get(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $src to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// MakeOrderedLayoutOp (cute.make_ordered_layout)
//===----------------------------------------------------------------------===//

LogicalResult MakeOrderedLayoutOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);

  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }
  auto orderTy = llvm::dyn_cast<IntTupleType>(adaptor.getOrder().getType());
  if (!orderTy) {
    return emitOptionalError(location,
                             "expects order to be !cute.int_tuple, but got ",
                             adaptor.getOrder().getType());
  }

  if (!orderTy.isStatic()) {
    return emitOptionalError(location,
                             "expects order to be a static int_tuple,"
                             " but got ",
                             orderTy);
  }

  const cg::shape &shape = shapeTy.getRef();
  const cg::int_tuple &order = orderTy.getRef();
  if (!cg::weakly_congruent(order, shape)) {
    return emitOptionalError(location,
                             "expects order to be weakly congruent to shape ",
                             shapeTy, ", but got ", orderTy);
  }

  cg::layout lay(shape, cg::compact_order<cg::stride>(shape, order));
  if (!cg::is_valid(lay)) {
    return emitOptionalError(location,
                             "expects a valid ordered layout, but construction"
                             " failed");
  }

  inferredReturnTypes.push_back(LayoutType::get(context, std::move(lay)));
  return success();
}

//===----------------------------------------------------------------------===//
// MakeIdentityLayoutOp (cute.make_identity_layout)
//===----------------------------------------------------------------------===//

LogicalResult MakeIdentityLayoutOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);

  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }

  cg::layout lay = cg::make_identity_layout(shapeTy.getRef());
  if (!cg::is_valid(lay)) {
    return emitOptionalError(location, "expects a valid identity layout from ",
                             shapeTy, ", but construction failed");
  }

  inferredReturnTypes.push_back(LayoutType::get(context, std::move(lay)));
  return success();
}

//===----------------------------------------------------------------------===//
// GetShapeOp (cute.get_shape)
//===----------------------------------------------------------------------===//

LogicalResult GetShapeOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<LayoutType, ComposedLayoutType>([&](auto ty) -> LogicalResult {
        // In composed layout case, cutegen returns the shape of the outer B
        // layout.
        inferredReturnTypes.push_back(
            ShapeType::get(context, ty.getRef().shape()));
        return success();
      })
      .Case<TileType>([&](TileType ty) -> LogicalResult {
        // Reject any tile with underscore slots. An underscore slot has
        // no shape. For tiles with underscore slots, callers should get
        // the layout slots first via cute.get_layouts_from_tile and then
        // take the shape of each layout.
        if (cg::has_underscore(ty.getRef())) {
          return emitOptionalError(
              location,
              "expects a tile operand with no underscore slots, but got ", ty);
        }
        inferredReturnTypes.push_back(
            ShapeType::get(context, cg::extract_shape_from_tile(ty.getRef())));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType|TileType");
      });
}

//===----------------------------------------------------------------------===//
// GetStrideOp (cute.get_stride)
//===----------------------------------------------------------------------===//

LogicalResult GetStrideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<LayoutType>(adaptor.getInput().getType());
  if (!ty) {
    return emitOptionalError(location,
                             "expects input to be !cute.layout, but got ",
                             adaptor.getInput().getType());
  }
  inferredReturnTypes.push_back(StrideType::get(context, ty.getRef().stride()));
  return success();
}

//===----------------------------------------------------------------------===//
// ComposedGetInnerOp (cute.composed_get_inner)
//===----------------------------------------------------------------------===//

LogicalResult ComposedGetInnerOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<ComposedLayoutType>(adaptor.getInput().getType());
  if (!ty) {
    return emitOptionalError(
        location, "expects input to be !cute.composed_layout, but got ",
        adaptor.getInput().getType());
  }
  if (ty.getRef().is_a_affine()) {
    inferredReturnTypes.push_back(
        LayoutType::get(context, ty.getRef().layout_a()));
  } else {
    inferredReturnTypes.push_back(
        SwizzleType::get(context, ty.getRef().swizzle_a()));
  }
  return success();
}

//===----------------------------------------------------------------------===//
// ComposedGetOffsetOp (cute.composed_get_offset)
//===----------------------------------------------------------------------===//

LogicalResult ComposedGetOffsetOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<ComposedLayoutType>(adaptor.getInput().getType());
  if (!ty) {
    return emitOptionalError(
        location, "expects input to be !cute.composed_layout, but got ",
        adaptor.getInput().getType());
  }
  inferredReturnTypes.push_back(
      IntTupleType::get(context, ty.getRef().offset()));
  return success();
}

//===----------------------------------------------------------------------===//
// ComposedGetOuterOp (cute.composed_get_outer)
//===----------------------------------------------------------------------===//

LogicalResult ComposedGetOuterOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<ComposedLayoutType>(adaptor.getInput().getType());
  if (!ty) {
    return emitOptionalError(
        location, "expects input to be !cute.composed_layout, but got ",
        adaptor.getInput().getType());
  }
  inferredReturnTypes.push_back(
      LayoutType::get(context, ty.getRef().layout_b()));
  return success();
}

//===----------------------------------------------------------------------===//
// GetLeavesOp (cute.get_leaves)
//===----------------------------------------------------------------------===//

LogicalResult GetLeavesOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<ShapeType, StrideType, CoordType, IntTupleType>(
          [&](auto ty) -> LogicalResult {
            auto flat = cg::flatten(ty.getRef());
            for (size_t i = 0; i < cg::rank(flat); ++i) {
              inferredReturnTypes.push_back(
                  std::decay_t<decltype(ty)>::get(context, flat[i]));
            }
            return success();
          })
      .Case<TileType>([&](TileType ty) -> LogicalResult {
        auto flat = cg::flatten(ty.getRef());
        for (size_t i = 0; i < cg::rank(flat); ++i) {
          flat[i].visit([&](const auto &elem) {
            using T = std::decay_t<decltype(elem)>;
            if constexpr (cg::is_layout<T>::value) {
              inferredReturnTypes.push_back(LayoutType::get(context, elem));
            } else if constexpr (!std::is_same_v<T, std::vector<cg::tile>>) {
              inferredReturnTypes.push_back(TileType::get(context, flat[i]));
            }
          });
        }
        return success();
      })
      .Default([&](Type ty) -> LogicalResult {
        return emitOptionalError(
            location,
            "expects $input to be !cute.shape, !cute.stride, !cute.coord, "
            "!cute.int_tuple, or !cute.tile, but got ",
            ty);
      });
}

//===----------------------------------------------------------------------===//
// GetScalarsOp (cute.get_scalars)
//===----------------------------------------------------------------------===//

LogicalResult GetScalarsOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  Type valueType = adaptor.getCuteValue().getType();
  bool onlyDynamic = adaptor.getOnlyDynamic();

  SmallVector<Type> scratch;
  return llvm::TypeSwitch<Type, LogicalResult>(valueType)
      .Case<IntTupleType, ShapeType, StrideType, CoordType, TileType,
            LayoutType, ComposedLayoutType>([&](auto ty) -> LogicalResult {
        cg::collect_scalar_types(context, ty.getRef(), scratch, onlyDynamic);
        inferredReturnTypes.append(scratch.begin(), scratch.end());
        return success();
      })
      .Case<SwizzleType>([&](SwizzleType ty) -> LogicalResult {
        // Per cute.get_scalars ODS: a swizzle yields three i32
        // results (num_bits, num_base, num_shift) — all
        // compile-time facts in the type signature. With
        // only_dynamic set, the swizzle has no dynamic leaves and
        // the op returns zero results.
        if (onlyDynamic) {
          return success();
        }
        inferredReturnTypes.push_back(IntegerType::get(context, 32));
        inferredReturnTypes.push_back(IntegerType::get(context, 32));
        inferredReturnTypes.push_back(IntegerType::get(context, 32));
        return success();
      })
      .Default([&](Type ty) -> LogicalResult {
        return emitOptionalError(
            location,
            "expects $cute_value to be !cute.int_tuple, !cute.shape, "
            "!cute.stride, !cute.coord, !cute.tile, !cute.layout, "
            "!cute.composed_layout, or !cute.swizzle, but got ",
            ty);
      });
}

// Validate nested mode indices for a type. Two failure modes:
// out-of-range index at some depth (emitBounds), or descent past a
// scalar leaf with indices left to consume (emitScalar). cg::depth
// discriminates leaves (0) from tuples/multi-mode (>=1) uniformly
// across rec_var kinds and layout/tile/composed_layout.
//
// Used for GetOp, SizeOp, CosizeOp.
template <typename TyClass, typename BoundsEmitFn, typename ScalarEmitFn>
static LogicalResult validateNestedModeIndices(TyClass ty,
                                               ArrayRef<int32_t> mode,
                                               BoundsEmitFn &&emitBounds,
                                               ScalarEmitFn &&emitScalar) {
  for (int32_t depth = 0; depth < static_cast<int32_t>(mode.size()); ++depth) {
    if (!cg::check_get_indices(ty.getRef(), mode.slice(0, depth + 1))) {
      auto sub = cg::get(ty.getRef(), mode.slice(0, depth));
      return emitBounds(static_cast<size_t>(depth),
                        static_cast<size_t>(cg::rank(sub)), mode[depth]);
    }
    if (depth + 1 < static_cast<int32_t>(mode.size())) {
      auto sub = cg::get(ty.getRef(), mode.slice(0, depth + 1));
      if (cg::depth(sub) == 0) {
        size_t extras = mode.size() - static_cast<size_t>(depth + 1);
        return emitScalar(static_cast<size_t>(depth + 1), extras);
      }
    }
  }
  return success();
}

//===----------------------------------------------------------------------===//
// GetOp (cute.get)
//===----------------------------------------------------------------------===//

LogicalResult
GetOp::inferReturnTypes(MLIRContext *context, std::optional<Location> location,
                        ValueRange operands, DictionaryAttr attributes,
                        PropertyRef properties, RegionRange /*regions*/,
                        SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto modes = adaptor.getMode().value_or(ArrayRef<int32_t>{});
  Type inputTy = adaptor.getInput().getType();

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<ShapeType, StrideType, CoordType, IntTupleType, TileType,
            LayoutType, ComposedLayoutType>([&](auto ty) -> LogicalResult {
        auto nestedModeValidation = validateNestedModeIndices(
            ty, modes,
            /*emitBounds=*/
            [&](size_t depth, size_t rank, int32_t bad) {
              return emitOptionalError(location, "expects mode index in [0, ",
                                       rank, ") at depth ", depth, ", but got ",
                                       bad);
            },
            /*emitScalar=*/
            [&](size_t depth, size_t extras) {
              return emitOptionalError(
                  location,
                  "expects mode indices to stop at a scalar leaf, but got ",
                  extras, extras == 1 ? " extra index" : " extra indices",
                  " after depth ", depth);
            });

        if (failed(nestedModeValidation)) {
          return failure();
        }
        inferredReturnTypes.push_back(std::decay_t<decltype(ty)>::get(
            context, cg::get(ty.getRef(), modes)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "ShapeType|IntTupleType|CoordType|StrideType|TileType|"
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// SelectOp (cute.select)
//===----------------------------------------------------------------------===//

LogicalResult SelectOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto modes = adaptor.getMode();
  Type inputTy = adaptor.getInput().getType();

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<ShapeType, StrideType, CoordType, IntTupleType, TileType,
            LayoutType, ComposedLayoutType>([&](auto ty) -> LogicalResult {
        const auto &cgTy = ty.getRef();
        size_t inputRank = cg::rank(cgTy);
        // Check that all modes in select modes are within range for the rank
        for (int32_t m : modes) {
          if (m < 0 || static_cast<size_t>(m) >= inputRank) {
            return emitOptionalError(location, "expects mode index in [0, ",
                                     inputRank, "), but got ", m);
          }
        }
        auto resTy = cg::select(ty.getRef(), modes);
        if (!cg::is_valid(resTy)) {
          return emitOptionalError(
              location,
              "expects mode indices to yield a valid result, but got "
              "invalid result for input type ",
              ty);
        }
        inferredReturnTypes.push_back(
            std::decay_t<decltype(ty)>::get(context, std::move(resTy)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "ShapeType|IntTupleType|CoordType|StrideType|TileType|"
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// ToIntTupleOp (cute.to_int_tuple)
//===----------------------------------------------------------------------===//

LogicalResult ToIntTupleOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getSrc().getType())
      .Case<ShapeType, StrideType, CoordType, IntTupleType>(
          [&](auto ty) -> LogicalResult {
            if (cg::has_error(ty.getRef())) {
              return emitOptionalError(
                  location, "expects source without errors (x), but got ", ty);
            }
            if (cg::has_underscore(ty.getRef())) {
              // coord type can accept underscores which is invalid for
              // int_tuple type
              return emitOptionalError(
                  location, "expects source without underscores (_), but got ",
                  ty);
            }
            if (cg::has_scaled_basis(ty.getRef())) {
              // stride type can accept scaled-basis which is invalid for
              // int_tuple type
              return emitOptionalError(location,
                                       "expects source without scaled-basis"
                                       " strides, but got ",
                                       ty);
            }
            inferredReturnTypes.push_back(IntTupleType::get(
                context, cg::rec_var_cast<cg::int_tuple>(ty.getRef())));
            return success();
          })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $src to "
                         "ShapeType|StrideType|CoordType|IntTupleType");
      });
}

//===----------------------------------------------------------------------===//
// ToShapeOp (cute.to_shape)
//===----------------------------------------------------------------------===//

LogicalResult ToShapeOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<IntTupleType>(adaptor.getSrc().getType());
  // int_tuple type accepts scalars that are subset of what is accepted by the
  // shape type
  if (!ty) {
    return emitOptionalError(location,
                             "expects src to be !cute.int_tuple, but got ",
                             adaptor.getSrc().getType());
  }
  if (cg::has_error(ty.getRef())) {
    return emitOptionalError(location,
                             "expects source without errors, but got ", ty);
  }
  inferredReturnTypes.push_back(
      ShapeType::get(context, cg::rec_var_cast<cg::shape>(ty.getRef())));
  return success();
}

//===----------------------------------------------------------------------===//
// ToStrideOp (cute.to_stride)
//===----------------------------------------------------------------------===//

LogicalResult ToStrideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<IntTupleType>(adaptor.getSrc().getType());
  // int_tuple type accepts scalars that are subset of what is accepted by the
  // stride type
  if (!ty) {
    return emitOptionalError(location,
                             "expects src to be !cute.int_tuple, but got ",
                             adaptor.getSrc().getType());
  }
  if (cg::has_error(ty.getRef())) {
    return emitOptionalError(location,
                             "expects source without errors, but got ", ty);
  }
  inferredReturnTypes.push_back(
      StrideType::get(context, cg::rec_var_cast<cg::stride>(ty.getRef())));
  return success();
}

//===----------------------------------------------------------------------===//
// ToCoordOp (cute.to_coord)
//===----------------------------------------------------------------------===//

LogicalResult ToCoordOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<IntTupleType>(adaptor.getSrc().getType());
  // int_tuple type accepts scalars that are subset of what is accepted by the
  // coord type
  if (!ty) {
    return emitOptionalError(location,
                             "expects src to be !cute.int_tuple, but got ",
                             adaptor.getSrc().getType());
  }
  if (cg::has_error(ty.getRef())) {
    return emitOptionalError(location,
                             "expects source without errors, but got ", ty);
  }
  inferredReturnTypes.push_back(
      CoordType::get(context, cg::rec_var_cast<cg::coord>(ty.getRef())));
  return success();
}

//===----------------------------------------------------------------------===//
// GetLayoutsFromTileOp (cute.get_layouts_from_tile)
//===----------------------------------------------------------------------===//

LogicalResult GetLayoutsFromTileOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto ty = llvm::dyn_cast<TileType>(adaptor.getTile().getType());
  if (!ty) {
    return emitOptionalError(location,
                             "expects tile to be !cute.tile, but got ",
                             adaptor.getTile().getType());
  }
  auto flat = cg::flatten(ty.getRef());
  for (size_t i = 0; i < cg::rank(flat); ++i) {
    flat[i].visit([&](const auto &elem) {
      if constexpr (cg::is_layout<std::decay_t<decltype(elem)>>::value) {
        inferredReturnTypes.push_back(LayoutType::get(context, elem));
      }
    });
  }
  // Reject all-underscore tiles. With zero layout leaves the op would
  // produce a zero-result variadic op, which is almost always a use
  // error — there is nothing to extract.
  if (inferredReturnTypes.empty()) {
    return emitOptionalError(
        location, "expects $tile to contain at least one layout slot, but got ",
        ty);
  }
  return success();
}

//===----------------------------------------------------------------------===//
// CompositionOp (cute.composition)
//===----------------------------------------------------------------------===//

LogicalResult CompositionOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto lhsTy = adaptor.getLhs().getType();
  auto rhsTy = adaptor.getRhs().getType();

  // Compute the composition.  The result kind always matches the lhs kind.
  return llvm::TypeSwitch<Type, LogicalResult>(lhsTy)
      .Case<LayoutType, ComposedLayoutType>([&](auto lhs) -> LogicalResult {
        return llvm::TypeSwitch<Type, LogicalResult>(rhsTy)
            .Case<LayoutType, ShapeType, TileType>(
                [&](auto rhs) -> LogicalResult {
                  auto composed = cg::composition(lhs.getRef(), rhs.getRef());
                  if (!cg::is_valid(composed)) {
                    return emitOptionalError(
                        location,
                        "expects a valid composition result, but construction "
                        "failed");
                  }
                  using TyClass = std::decay_t<decltype(lhs)>;
                  inferredReturnTypes.push_back(
                      pickNormalOrComposedLayoutType<TyClass>(
                          context, std::move(composed)));
                  return success();
                })
            .Default([](Type) -> LogicalResult {
              llvm_unreachable("ODS constrains $rhs to "
                               "LayoutType|ShapeType|TileType");
            });
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// CoalesceOp (cute.coalesce)
//===----------------------------------------------------------------------===//

/// Recursive precondition check for cute.coalesce's target_profile:
/// at every nesting depth the profile's rank must not exceed the layout's
/// rank. The path accumulates the mode indices walked so the diagnostic
/// can point to the failing depth.
static LogicalResult recursiveCheckTargetProfileRank(
    std::optional<Location> location, const cg::layout &layout,
    const cg::coord &profile, SmallVectorImpl<size_t> &path) {
  // Scalar profile is always fine — cutegen falls back to the no-profile
  // coalesce form at this depth.
  if (!cg::holds_vector(profile)) {
    return success();
  }

  auto profileRank = static_cast<int64_t>(cg::rank(profile));
  auto layoutRank = static_cast<int64_t>(cg::rank(layout.shape()));
  if (profileRank > layoutRank) {
    SmallString<64> pathSuffix;
    if (!path.empty()) {
      llvm::raw_svector_ostream os(pathSuffix);
      os << " at mode path [";
      llvm::interleaveComma(path, os);
      os << "]";
    }
    return emitOptionalError(location, "expects target_profile rank (",
                             profileRank, ") to not exceed the layout rank (",
                             layoutRank, ")", StringRef(pathSuffix));
  }

  for (size_t i = 0; i < static_cast<size_t>(profileRank); ++i) {
    auto profileMode = cg::get(profile, i);
    auto layoutMode = cg::get(layout, i);
    path.push_back(i);
    auto result = recursiveCheckTargetProfileRank(location, layoutMode,
                                                  profileMode, path);
    path.pop_back();
    if (failed(result)) {
      return result;
    }
  }

  return success();
}

LogicalResult CoalesceOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto inputTy = adaptor.getInput().getType();

  // Pre-validate the union type so the unchecked cast in the rank-validation
  // pre-check below is safe.
  if (!llvm::isa<LayoutType, ComposedLayoutType>(inputTy)) {
    return emitOptionalError(
        location, "expects input to be a layout or composed layout, but got ",
        inputTy);
  }

  // Validate the optional target_profile operand up-front so the
  // subsequent rank check and the per-case coalesce call below can both
  // reuse the resolved CoordType without re-casting.
  CoordType targetProfileTy;
  if (adaptor.getTargetProfile()) {
    targetProfileTy =
        llvm::dyn_cast<CoordType>(adaptor.getTargetProfile().getType());
    if (!targetProfileTy) {
      return emitOptionalError(location,
                               "expects target_profile to be !cute.coord, "
                               "but got ",
                               adaptor.getTargetProfile().getType());
    }
  }

  // Pre-condition: at every nesting depth the target_profile's rank must
  // not exceed the layout's rank. For a composed_layout the profile is
  // applied to the B component, so walk against B.
  if (targetProfileTy) {
    const auto &profileRef = targetProfileTy.getRef();
    const cg::layout &layoutForRank =
        llvm::isa<LayoutType>(inputTy)
            ? llvm::cast<LayoutType>(inputTy).getRef()
            : llvm::cast<ComposedLayoutType>(inputTy).getRef().layout_b();
    SmallVector<size_t, 4> path;
    if (failed(recursiveCheckTargetProfileRank(location, layoutForRank,
                                               profileRef, path))) {
      return failure();
    }
  }

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<LayoutType, ComposedLayoutType>(
          [&](auto inputLay) -> LogicalResult {
            auto result =
                targetProfileTy
                    ? cg::coalesce(inputLay.getRef(), targetProfileTy.getRef())
                    : cg::coalesce(inputLay.getRef());
            if (!cg::is_valid(result)) {
              return emitOptionalError(
                  location,
                  "expects a valid coalesce result, but construction failed ");
            }
            using TyClass = std::decay_t<decltype(inputLay)>;
            // Simplify the result to normal layout if possible.
            inferredReturnTypes.push_back(
                pickNormalOrComposedLayoutType<TyClass>(context,
                                                        std::move(result)));
            return success();
          })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// FlattenOp (cute.flatten)
//===----------------------------------------------------------------------===//

LogicalResult FlattenOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  FlattenOpAdaptor adaptor(operands, attributes, properties);
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<ShapeType, StrideType, CoordType, IntTupleType, TileType,
            LayoutType, ComposedLayoutType>([&](auto inputTy) -> LogicalResult {
        using TyClass = std::decay_t<decltype(inputTy)>;
        auto result = cg::flatten(inputTy.getRef());
        if (!cg::is_valid(result)) {
          return emitOptionalError(
              location,
              "expects a valid flatten result, but construction failed");
        }
        inferredReturnTypes.push_back(pickNormalOrComposedLayoutType<TyClass>(
            context, std::move(result)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to ShapeType|StrideType|"
                         "CoordType|IntTupleType|TileType|LayoutType|"
                         "ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// ComplementOp (cute.complement)
//===----------------------------------------------------------------------===//

LogicalResult ComplementOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  auto inputTy = llvm::dyn_cast<LayoutType>(adaptor.getInput().getType());
  if (!inputTy) {
    return emitOptionalError(location,
                             "expects input to be !cute.layout, but got ",
                             adaptor.getInput().getType());
  }
  const auto &inputRef = inputTy.getRef();

  // No-cotarget path: dispatch to cutegen's complement(layout) overload.
  if (!adaptor.getCotarget()) {
    if (!cg::is_static(inputRef)) {
      return emitOptionalError(location,
                               "expects input with static layout, but got",
                               inputTy, " with dynamic layout");
    }
    auto result = cg::complement(inputRef);
    if (!cg::is_valid(result)) {
      return emitOptionalError(location,
                               "expects a valid intrinsic complement result, "
                               "but construction failed for input ",
                               inputTy);
    }
    inferredReturnTypes.push_back(LayoutType::get(context, std::move(result)));
    return success();
  }

  // Cotarget-aware path: mirror cutegen's two preconditions for
  // complement(layout, cosize_hi) (cutegen/layout.hpp) with
  // targeted diagnostics.

  // Pre-condition: strides must be scalar integers (static or dynamic).
  // Scaled-basis and ratio strides are not supported by the cotarget-aware
  // overload (cutegen/layout.hpp).
  if (!cg::is_int_or_dynamic_int_only(inputRef.stride())) {
    return emitOptionalError(location,
                             "expects input with integer strides, but ",
                             inputTy, " has non-integer strides");
  }

  // Pre-condition: multi-mode layouts must have all-static strides
  // (cutegen/layout.hpp). Only rank-1 layouts may carry a dynamic
  // stride.
  if (!cg::is_static(inputRef.stride()) && cg::rank(inputRef.shape()) > 1) {
    return emitOptionalError(location,
                             "expects input with static strides for layouts "
                             "with more than one mode, "
                             "but ",
                             inputTy, " has dynamic strides with rank ",
                             cg::rank(inputRef.shape()));
  }

  // Extract the cotarget shape uniformly: ShapeType has it directly,
  // LayoutType has it as the shape() of its layout ref. Either is valid;
  // anything else (despite the ODS constraint) gets a clean diagnostic
  // here rather than a downstream cast assert.
  Type cotargetTy = adaptor.getCotarget().getType();
  cg::shape cotargetShape;
  if (auto shapeTy = llvm::dyn_cast<ShapeType>(cotargetTy)) {
    cotargetShape = shapeTy.getRef();
  } else if (auto layoutTy = llvm::dyn_cast<LayoutType>(cotargetTy)) {
    cotargetShape = layoutTy.getRef().shape();
  } else {
    return emitOptionalError(location,
                             "expects cotarget to be !cute.shape or "
                             "!cute.layout, but got ",
                             cotargetTy);
  }

  auto result = cg::complement(inputRef, cotargetShape);
  if (!cg::is_valid(result)) {
    return emitOptionalError(location,
                             "expects a valid complement result, but "
                             "construction failed for input ",
                             inputTy, " with cotarget ", cotargetTy);
  }
  inferredReturnTypes.push_back(LayoutType::get(context, std::move(result)));
  return success();
}

//===----------------------------------------------------------------------===//
// GroupModesOp (cute.group_modes)
//===----------------------------------------------------------------------===//

LogicalResult GroupModesOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  GroupModesOpAdaptor adaptor(operands, attributes, properties);
  int begin = adaptor.getBegin();
  int end = adaptor.getEnd();

  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<LayoutType, ComposedLayoutType>([&](auto inputTy) -> LogicalResult {
        using TyClass = std::decay_t<decltype(inputTy)>;
        // For composed input, rank refers to the B-layout (group_modes
        // applies to B; A and offset are preserved).
        int rank;
        if constexpr (std::is_same_v<TyClass, ComposedLayoutType>) {
          rank =
              static_cast<int>(cg::rank(inputTy.getRef().layout_b().shape()));
        } else {
          rank = static_cast<int>(cg::rank(inputTy.getRef().shape()));
        }
        if (begin < 0) {
          return emitOptionalError(location,
                                   "expects 0 <= begin, but got begin=", begin);
        }
        if (end <= begin) {
          return emitOptionalError(location,
                                   "expects begin < end, but got begin=", begin,
                                   ", end=", end);
        }
        if (end > rank) {
          return emitOptionalError(location,
                                   "expects end <= rank(input)=", rank,
                                   ", but got end=", end);
        }
        auto result = cg::group(begin, end, inputTy.getRef());
        if (!cg::is_valid(result)) {
          return emitOptionalError(location,
                                   "expects a valid group_modes result, but "
                                   "construction failed for input ",
                                   inputTy, " with [begin=", begin,
                                   ", end=", end, ")");
        }
        inferredReturnTypes.push_back(pickNormalOrComposedLayoutType<TyClass>(
            context, std::move(result)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// RecastLayoutOp (cute.recast_layout)
//===----------------------------------------------------------------------===//

LogicalResult RecastLayoutOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  RecastLayoutOpAdaptor adaptor(operands, attributes, properties);
  int newBits = adaptor.getNewTypeBits();
  int oldBits = adaptor.getOldTypeBits();

  if (newBits <= 0) {
    return emitOptionalError(
        location, "expects new_type_bits to be positive, but got ", newBits);
  }
  if (oldBits <= 0) {
    return emitOptionalError(
        location, "expects old_type_bits to be positive, but got ", oldBits);
  }

  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getSrc().getType())
      .Case<LayoutType, ComposedLayoutType>([&](auto srcTy) -> LogicalResult {
        using TyClass = std::decay_t<decltype(srcTy)>;
        // For composed inputs, the scaled-basis check applies to the
        // outer (B) layout's stride; for plain layouts, the input's
        // own stride.
        bool validStride;
        if constexpr (std::is_same_v<TyClass, ComposedLayoutType>) {
          validStride = cg::is_int_or_dynamic_int_only(
              srcTy.getRef().layout_b().stride());
        } else {
          validStride = cg::is_int_or_dynamic_int_only(srcTy.getRef().stride());
        }
        if (!validStride) {
          return emitOptionalError(location,
                                   "expects integer or dynamic strides, but ",
                                   srcTy, " has scaled-basis strides");
        }
        auto res = cg::recast(newBits, oldBits, srcTy.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location, "unable to recast ", srcTy,
                                   " from ", oldBits, " bits to ", newBits,
                                   " bits");
        }
        inferredReturnTypes.push_back(
            pickNormalOrComposedLayoutType<TyClass>(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $src to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// SliceOp (cute.slice)
//===----------------------------------------------------------------------===//

LogicalResult SliceOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  SliceOpAdaptor adaptor(operands, attributes, properties);
  auto coordTy = llvm::dyn_cast<CoordType>(adaptor.getCoord().getType());
  if (!coordTy) {
    return emitOptionalError(location,
                             "expects coord to be !cute.coord, but got ",
                             adaptor.getCoord().getType());
  }
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<ShapeType, StrideType, IntTupleType, CoordType, LayoutType,
            ComposedLayoutType>([&](auto inputTy) -> LogicalResult {
        if (!cg::weakly_congruent(coordTy.getRef(), inputTy.getRef())) {
          return emitOptionalError(location,
                                   "expects coord to be weakly congruent with "
                                   "input shape, but got ",
                                   inputTy, " and ", coordTy);
        }
        // Swizzle-A composed slice has stricter preconditions than the
        // affine-A / plain-layout / tuple-kind paths. Hoist the reachable
        // checks from cutegen's slice_and_offset(swizzle&, ...)
        // (composed_layout.hpp) so each gets a specific diagnostic.
        //

        // Cutegen also rejects scaled-basis outer stride and non-scalar
        // offsets in this path, but the swizzle composed_layout type
        // itself enforces both at parse time ("swizzle layout expects
        // scalar offset and outer without scaled basis"), so they
        // are unreachable here.
        if constexpr (std::is_same_v<std::decay_t<decltype(inputTy)>,
                                     ComposedLayoutType>) {
          const auto &cl = inputTy.getRef();
          if (cl.is_a_swizzle()) {
            if (!cg::is_static(cl.layout_b())) {
              return emitOptionalError(
                  location,
                  "expects swizzle-A composed slice's outer layout to be "
                  "static, but got ",
                  inputTy);
            }
            if (!cg::has_underscore(coordTy.getRef())) {
              return emitOptionalError(
                  location,
                  "expects swizzle-A composed slice's coord to contain at "
                  "least one underscore, but got ",
                  coordTy);
            }
          }
        }
        auto res = cg::slice(coordTy.getRef(), inputTy.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location, "unable to slice ", inputTy,
                                   " with ", coordTy);
        }
        using TyClass = std::decay_t<decltype(inputTy)>;
        inferredReturnTypes.push_back(
            pickNormalOrComposedLayoutType<TyClass>(context, std::move(res)));
        return success();
      })
      .Default([&](Type ty) -> LogicalResult {
        return emitOptionalError(
            location,
            "expects $input to be !cute.shape, !cute.stride, !cute.int_tuple, "
            "!cute.coord, !cute.layout, or !cute.composed_layout, but got ",
            ty);
      });
}

//===----------------------------------------------------------------------===//
// DiceOp (cute.dice)
//===----------------------------------------------------------------------===//

LogicalResult
DiceOp::inferReturnTypes(MLIRContext *context, std::optional<Location> location,
                         ValueRange operands, DictionaryAttr attributes,
                         PropertyRef properties, RegionRange /*regions*/,
                         SmallVectorImpl<Type> &inferredReturnTypes) {
  DiceOpAdaptor adaptor(operands, attributes, properties);
  auto coordTy = llvm::dyn_cast<CoordType>(adaptor.getCoord().getType());
  if (!coordTy) {
    return emitOptionalError(location,
                             "expects coord to be !cute.coord, but got ",
                             adaptor.getCoord().getType());
  }
  if (!coordTy.isStatic()) {
    return emitOptionalError(location, "expects coord to be static, but got ",
                             coordTy);
  }
  return llvm::TypeSwitch<Type, LogicalResult>(adaptor.getInput().getType())
      .Case<ShapeType, StrideType, IntTupleType, CoordType, LayoutType,
            ComposedLayoutType>([&](auto inputTy) -> LogicalResult {
        if (!cg::weakly_congruent(coordTy.getRef(), inputTy.getRef())) {
          return emitOptionalError(location,
                                   "expects coord to be weakly congruent with "
                                   "input shape, but got ",
                                   inputTy, " and ", coordTy);
        }
        auto res = cg::dice(coordTy.getRef(), inputTy.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location, "unable to dice ", inputTy,
                                   " with ", coordTy);
        }
        using TyClass = std::decay_t<decltype(inputTy)>;
        inferredReturnTypes.push_back(
            pickNormalOrComposedLayoutType<TyClass>(context, std::move(res)));
        return success();
      })
      .Default([&](Type ty) -> LogicalResult {
        return emitOptionalError(
            location,
            "expects $input to be !cute.shape, !cute.stride, !cute.int_tuple, "
            "!cute.coord, !cute.layout, or !cute.composed_layout, but got ",
            ty);
      });
}

// Shared inferReturnTypes body for cute.right_inverse and
// cute.left_inverse. The two ops differ in:
//   - the cutegen function called (cgFn),
//   - the diagnostic noun ("right" / "left"),
//   - the shape pre-condition, and
//   - the stride pre-condition: right_inverse accepts dynamic stride leaves
//     for static-shape inputs and fully static integer strides for dynamic
//     shapes, while left_inverse requires the stride to be fully static
//     (cutegen/layout.hpp).
//

// requireStaticShape and requireStaticStride toggle the corresponding
// pre-condition checks. cgFn is passed as a callable so cutegen's template
// TDynTraits parameter is deduced from cg::layout at the call site.
template <typename Fn>
static LogicalResult
inferInverseReturnTypes(MLIRContext *context, std::optional<Location> location,
                        LayoutType inputTy, StringRef kindName,
                        bool requireStaticShape, bool requireStaticStride,
                        Fn &&cgFn,
                        SmallVectorImpl<Type> &inferredReturnTypes) {
  const auto &ref = inputTy.getRef();
  if (requireStaticShape && !cg::is_static(ref.shape())) {
    return emitOptionalError(location,
                             "expects a static-shape input layout, "
                             "but got ",
                             inputTy);
  }
  if (!requireStaticShape && !cg::is_static(ref.shape()) &&
      !cg::is_integral_only(ref.stride())) {
    return emitOptionalError(
        location,
        "expects a dynamic-shape input layout to have fully static integer "
        "strides, but got ",
        inputTy);
  }
  if (requireStaticStride && !cg::is_static(ref.stride())) {
    return emitOptionalError(location,
                             "expects a static-stride input layout for ",
                             kindName, " inverse, but got ", inputTy);
  }
  cg::layout inv = std::forward<Fn>(cgFn)(ref);
  if (!cg::is_valid(inv)) {
    return emitOptionalError(location, "unable to compute a ", kindName,
                             " inverse for ", inputTy);
  }
  inferredReturnTypes.push_back(LayoutType::get(context, std::move(inv)));
  return success();
}

//===----------------------------------------------------------------------===//
// RightInverseOp (cute.right_inverse)
//===----------------------------------------------------------------------===//

LogicalResult RightInverseOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  RightInverseOpAdaptor adaptor(operands, attributes, properties);
  auto inputTy = llvm::dyn_cast<LayoutType>(adaptor.getInput().getType());
  if (!inputTy) {
    return emitOptionalError(location,
                             "expects input to be !cute.layout, but got ",
                             adaptor.getInput().getType());
  }
  return inferInverseReturnTypes(
      context, location, inputTy, "right", /*requireStaticShape=*/false,
      /*requireStaticStride=*/false,
      [](const cg::layout &l) { return cg::right_inverse(l); },
      inferredReturnTypes);
}

//===----------------------------------------------------------------------===//
// LeftInverseOp (cute.left_inverse)
//===----------------------------------------------------------------------===//

LogicalResult LeftInverseOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  LeftInverseOpAdaptor adaptor(operands, attributes, properties);
  auto inputTy = llvm::dyn_cast<LayoutType>(adaptor.getInput().getType());
  if (!inputTy) {
    return emitOptionalError(location,
                             "expects input to be !cute.layout, but got ",
                             adaptor.getInput().getType());
  }
  return inferInverseReturnTypes(
      context, location, inputTy, "left", /*requireStaticShape=*/true,
      /*requireStaticStride=*/true,
      [](const cg::layout &l) { return cg::left_inverse(l); },
      inferredReturnTypes);
}

//===----------------------------------------------------------------------===//
// SizeOp (cute.size)
//===----------------------------------------------------------------------===//

LogicalResult
SizeOp::inferReturnTypes(MLIRContext *context, std::optional<Location> location,
                         ValueRange operands, DictionaryAttr attributes,
                         PropertyRef properties, RegionRange /*regions*/,
                         SmallVectorImpl<Type> &inferredReturnTypes) {
  SizeOpAdaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();
  auto mode = adaptor.getMode().value_or(ArrayRef<int32_t>{});

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<ShapeType, IntTupleType, LayoutType, ComposedLayoutType>(
          [&](auto ty) -> LogicalResult {
            auto nestedModeValidation = validateNestedModeIndices(
                ty, mode,
                /*emitBounds=*/
                [&](size_t depth, size_t rank, int32_t bad) {
                  return emitOptionalError(
                      location, "expects mode index in [0, ", rank,
                      ") at depth ", depth, ", but got ", bad);
                },
                /*emitScalar=*/
                [&](size_t depth, size_t extras) {
                  return emitOptionalError(
                      location,
                      "expects mode indices to stop at a scalar leaf, but got ",
                      extras, extras == 1 ? " extra index" : " extra indices",
                      " after depth ", depth);
                });

            if (failed(nestedModeValidation)) {
              return failure();
            }

            cg::int_tuple res = cg::rec_var_cast<cg::int_tuple>(
                cg::size(cg::get(ty.getRef(), mode)));
            if (!cg::is_valid(res)) {
              return emitOptionalError(
                  location, "unable to compute size for input ", inputTy,
                  " and mode [", llvm::make_range(mode.begin(), mode.end()),
                  "]");
            }
            inferredReturnTypes.push_back(
                IntTupleType::get(context, std::move(res)));
            return success();
          })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable(
            "ODS constrains $input to "
            "ShapeType|IntTupleType|LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// CosizeOp (cute.cosize)
//===----------------------------------------------------------------------===//

LogicalResult CosizeOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  CosizeOpAdaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();
  auto mode = adaptor.getMode().value_or(ArrayRef<int32_t>{});

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<LayoutType, ComposedLayoutType>([&](auto ty) -> LogicalResult {
        using TyClass = decltype(ty);

        // Affine-inner composed layouts have no well-defined cosize
        if constexpr (std::is_same_v<TyClass, ComposedLayoutType>) {
          if (ty.getRef().is_a_affine()) {
            return emitOptionalError(
                location,
                "expects composed_layout inner to be a swizzle (cosize is "
                "undefined for affine inner), but got ",
                inputTy);
          }
        }

        auto nestedModeValidation = validateNestedModeIndices(
            ty, mode,
            /*emitBounds=*/
            [&](size_t depth, size_t rank, int32_t bad) {
              return emitOptionalError(location, "expects mode index in [0, ",
                                       rank, ") at depth ", depth, ", but got ",
                                       bad);
            },
            /*emitScalar=*/
            [&](size_t depth, size_t extras) {
              return emitOptionalError(
                  location,
                  "expects mode indices to stop at a scalar leaf, but got ",
                  extras, extras == 1 ? " extra index" : " extra indices",
                  " after depth ", depth);
            });

        if (failed(nestedModeValidation)) {
          return failure();
        }

        cg::int_tuple res = cg::rec_var_cast<cg::int_tuple>(
            cg::cosize(cg::get(ty.getRef(), mode)));
        if (!cg::is_valid(res)) {
          return emitOptionalError(
              location, "unable to compute cosize for input ", inputTy,
              " and mode [", llvm::make_range(mode.begin(), mode.end()), "]");
        }
        inferredReturnTypes.push_back(
            IntTupleType::get(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// TupleProductOp (cute.tuple_product)
//===----------------------------------------------------------------------===//

LogicalResult TupleProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  TupleProductOpAdaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();

  // Kind-preserving: cg::product returns a value of the same type as its input:
  // (shape -> shape, int_tuple -> int_tuple).
  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<IntTupleType, ShapeType>([&](auto ty) -> LogicalResult {
        auto res = cg::product(ty.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(
              location, "unable to compute tuple_product for input ", inputTy);
        }
        inferredReturnTypes.push_back(
            std::decay_t<decltype(ty)>::get(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "IntTupleType|ShapeType");
      });
}

//===----------------------------------------------------------------------===//
// TupleProductEachOp (cute.tuple_product_each)
//===----------------------------------------------------------------------===//

LogicalResult TupleProductEachOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  TupleProductEachOpAdaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();

  // Kind-preserving: cg::product_each returns a value of the same
  // type as its input: (shape -> shape, int_tuple -> int_tuple).
  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<IntTupleType, ShapeType>([&](auto ty) -> LogicalResult {
        auto res = cg::product_each(ty.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(
              location, "unable to compute tuple_product_each for input ",
              inputTy);
        }
        inferredReturnTypes.push_back(
            std::decay_t<decltype(ty)>::get(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "IntTupleType|ShapeType");
      });
}

//===----------------------------------------------------------------------===//
// LayoutEvalOp (cute.layout_eval)
//===----------------------------------------------------------------------===//

LogicalResult LayoutEvalOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  LayoutEvalOpAdaptor adaptor(operands, attributes, properties);
  auto coordTy = llvm::dyn_cast<CoordType>(adaptor.getCoord().getType());
  if (!coordTy) {
    return emitOptionalError(location,
                             "expects coord to be !cute.coord, but got ",
                             adaptor.getCoord().getType());
  }
  const cg::coord &coord = coordTy.getRef();

  // Rank pre-check (specific diagnostic before falling through to the
  // generic is_valid sentinel). For LayoutType, compare against the
  // layout's own shape; for ComposedLayoutType, compare against B's
  // shape since the coord flows into B first (A(offset + B(coord))).
  size_t shapeRank =
      llvm::TypeSwitch<Type, size_t>(adaptor.getLayout().getType())
          .Case<LayoutType>(
              [&](LayoutType ty) { return cg::rank(ty.getRef().shape()); })
          .Case<ComposedLayoutType>([&](ComposedLayoutType ty) {
            return cg::rank(ty.getRef().layout_b().shape());
          });
  if (!cg::holds_leaf(coord) && cg::rank(coord) != shapeRank) {
    return emitOptionalError(
        location, "expects coordinate rank ", shapeRank,
        " (to match layout shape rank) or be a leaf, but got ",
        cg::rank(coord));
  }

  cg::int_tuple res =
      llvm::TypeSwitch<Type, cg::int_tuple>(adaptor.getLayout().getType())
          .Case<LayoutType>([&](LayoutType ty) -> cg::int_tuple {
            const cg::layout &lay = ty.getRef();
            return cg::layout_eval(coord, lay.shape(), lay.stride());
          })
          .Case<ComposedLayoutType>(
              [&](ComposedLayoutType ty) -> cg::int_tuple {
                // Evaluate the composed layout A o offset o B by
                // explicit decomposition (layout_eval into B, sum with
                // offset, apply A). composed_layout::operator() does
                // not handle scaled-basis composed layouts.
                auto const &composed = ty.getRef();
                cg::int_tuple b_idx =
                    cg::layout_eval(coord, composed.layout_b().shape(),
                                    composed.layout_b().stride());
                cg::int_tuple sum = cg::arith_tuple_sum<cg::int_tuple>(
                    composed.offset(), b_idx);
                if (composed.is_a_swizzle()) {
                  return composed.swizzle_a()(sum);
                }
                auto const &A = composed.layout_a();
                return cg::layout_eval(sum, A.shape(), A.stride());
              });
  if (!cg::is_valid(res)) {
    return emitOptionalError(
        location, "unable to compute layout_eval for coordinate ", coordTy,
        " and layout ", adaptor.getLayout().getType());
  }
  inferredReturnTypes.push_back(IntTupleType::get(context, std::move(res)));
  return success();
}

//===----------------------------------------------------------------------===//
// Crd2IdxOp (cute.crd2idx)
//===----------------------------------------------------------------------===//

LogicalResult Crd2IdxOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Crd2IdxOpAdaptor adaptor(operands, attributes, properties);
  auto coordTy = llvm::dyn_cast<CoordType>(adaptor.getCoord().getType());
  if (!coordTy) {
    return emitOptionalError(location,
                             "expects coord to be !cute.coord, but got ",
                             adaptor.getCoord().getType());
  }
  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }
  const cg::coord &coord = coordTy.getRef();
  const cg::shape &shape = shapeTy.getRef();

  // Coord must be weakly congruent with shape (compatible nesting structure;
  // a scalar coord weakly-matches any shape).
  if (!cg::weakly_congruent(coord, shape)) {
    return emitOptionalError(
        location,
        "expects coord and shape to be weakly congruent, but got coord ",
        coordTy, " and shape ", shapeTy);
  }

  cg::int_tuple res = cg::crd2idx(coord, shape);
  if (!cg::is_valid(res)) {
    return emitOptionalError(location, "unable to pack coordinate ", coordTy,
                             " into shape ", shapeTy);
  }
  inferredReturnTypes.push_back(IntTupleType::get(context, std::move(res)));
  return success();
}

//===----------------------------------------------------------------------===//
// Idx2CrdOp (cute.idx2crd)
//===----------------------------------------------------------------------===//

LogicalResult Idx2CrdOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Idx2CrdOpAdaptor adaptor(operands, attributes, properties);
  auto indexTy = llvm::dyn_cast<IntTupleType>(adaptor.getIndex().getType());
  if (!indexTy) {
    return emitOptionalError(location,
                             "expects index to be !cute.int_tuple, but got ",
                             adaptor.getIndex().getType());
  }
  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }

  // Rank pre-check: multi-element index must match shape rank.
  // Scalar (rank-0 or rank-1) indices are unconditionally accepted.
  size_t indexRank = cg::rank(indexTy.getRef());
  size_t shapeRank = cg::rank(shapeTy.getRef());
  if (indexRank > 1 && indexRank != shapeRank) {
    return emitOptionalError(location, "expects index rank ", shapeRank,
                             " (to match shape rank) or scalar, but got ",
                             indexRank);
  }

  cg::coord res = cg::rec_var_cast<cg::coord>(
      cg::idx2crd(indexTy.getRef(), shapeTy.getRef()));
  if (!cg::is_valid(res)) {
    return emitOptionalError(location, "unable to compute idx2crd for index ",
                             indexTy, " and shape ", shapeTy);
  }
  inferredReturnTypes.push_back(CoordType::get(context, std::move(res)));
  return success();
}

//===----------------------------------------------------------------------===//
// IncrementCoordOp (cute.increment_coord)
//===----------------------------------------------------------------------===//

LogicalResult IncrementCoordOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  IncrementCoordOpAdaptor adaptor(operands, attributes, properties);
  auto coordTy = llvm::dyn_cast<CoordType>(adaptor.getCoord().getType());
  if (!coordTy) {
    return emitOptionalError(location,
                             "expects coord to be !cute.coord, but got ",
                             adaptor.getCoord().getType());
  }
  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }
  // Structural prechecks (split out to give each failure mode its own
  // specific diagnostic, matching the family convention).
  if (!cg::is_congruent(coordTy.getRef(), shapeTy.getRef())) {
    return emitOptionalError(
        location, "expects coord to be congruent with shape, but got ", coordTy,
        " and ", shapeTy);
  }
  if (cg::has_underscore(coordTy.getRef())) {
    return emitOptionalError(
        location, "expects coord to be free of underscore wildcards, but got ",
        coordTy);
  }
  cg::coord res = cg::increment_coord(coordTy.getRef(), shapeTy.getRef());
  if (!cg::is_valid(res)) {
    return emitOptionalError(location,
                             "unable to compute increment_coord for coord ",
                             coordTy, " and shape ", shapeTy);
  }
  inferredReturnTypes.push_back(CoordType::get(context, std::move(res)));
  return success();
}

template <typename OpAdaptorT>
static LogicalResult
inferXToRankReturnTypes(MLIRContext *context, std::optional<Location> location,
                        ValueRange operands, DictionaryAttr attributes,
                        PropertyRef properties, RegionRange /*regions*/,
                        SmallVectorImpl<Type> &inferredReturnTypes) {
  OpAdaptorT adaptor(operands, attributes, properties);
  constexpr bool isAppend = std::is_same_v<OpAdaptorT, AppendToRankOp::Adaptor>;

  Type inputTy = adaptor.getInput().getType();
  Type elemTy = adaptor.getElement().getType();
  int32_t rank = adaptor.getRank();
  if (rank <= 0) {
    return emitOptionalError(
        location, "expects rank to be a positive integer, but got ", rank);
  }

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .template Case<IntTupleType, CoordType, StrideType, ShapeType, LayoutType,
                     ComposedLayoutType>([&](auto inTy) {
        using InT = decltype(inTy);
        // For tuple-likes and plain layout the element must match the input
        // kind; for composed_layout the element must be a plain layout
        // (cutegen has no overload taking a composed element).
        using ElemT =
            std::conditional_t<std::is_same_v<InT, ComposedLayoutType>,
                               LayoutType, InT>;
        auto e = llvm::dyn_cast<ElemT>(elemTy);
        if (!e) {
          if constexpr (std::is_same_v<InT, ComposedLayoutType>) {
            return emitOptionalError(
                location,
                "expects element to be !cute.layout when input is "
                "!cute.composed_layout, but got ",
                elemTy);
          } else {
            return emitOptionalError(
                location,
                "expects input and element to have the same kind, but got ",
                inputTy, " and ", elemTy);
          }
        }
        auto res = isAppend ? cg::append_to_rank_N(static_cast<size_t>(rank),
                                                   inTy.getRef(), e.getRef())
                            : cg::prepend_to_rank_N(static_cast<size_t>(rank),
                                                    inTy.getRef(), e.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(
              location,
              "expects input and element to have the same kind, but got ",
              inputTy, " and ", elemTy);
        }
        inferredReturnTypes.push_back(InT::get(context, std::move(res)));
        return success();
      })
      .Default([&](Type ty) -> LogicalResult {
        return emitOptionalError(
            location,
            "expects $input to be !cute.int_tuple, !cute.coord, !cute.stride, "
            "!cute.shape, !cute.layout, or !cute.composed_layout, but got ",
            ty);
      });
}

//===----------------------------------------------------------------------===//
// AppendToRankOp
//===----------------------------------------------------------------------===//

LogicalResult AppendToRankOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange regions,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  return inferXToRankReturnTypes<AppendToRankOp::Adaptor>(
      context, location, operands, attributes, properties, regions,
      inferredReturnTypes);
}

//===----------------------------------------------------------------------===//
// PrependToRankOp
//===----------------------------------------------------------------------===//

LogicalResult PrependToRankOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange regions,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  return inferXToRankReturnTypes<PrependToRankOp::Adaptor>(
      context, location, operands, attributes, properties, regions,
      inferredReturnTypes);
}

//===----------------------------------------------------------------------===//
// Helper functions for TupleAddOp / TupleSubOp
//===----------------------------------------------------------------------===//

/// Recursively checks element positions of two tuple vectors for nesting
/// mismatches (one side a leaf, the other a sub-tuple).  Both @p lhs and
/// @p rhs must already be vectors when this is called (top-level scalar
/// cases are handled by the per-op wrappers below).
template <typename T>
static LogicalResult checkSubElementNesting(std::optional<Location> location,
                                            const T &lhs, const T &rhs,
                                            Type lhsMLIRTy, Type rhsMLIRTy) {
  size_t commonRank = std::min(cg::rank(lhs), cg::rank(rhs));
  for (size_t i = 0; i < commonRank; ++i) {
    bool elemLhsIsLeaf = cg::holds_leaf(lhs[i]);
    bool elemRhsIsLeaf = cg::holds_leaf(rhs[i]);
    if (elemLhsIsLeaf != elemRhsIsLeaf) {
      return emitOptionalError(location, "expects matching nesting at element ",
                               i, ", but got: ", lhsMLIRTy, " and ", rhsMLIRTy);
    }
    if (!elemLhsIsLeaf) {
      if (failed(checkSubElementNesting(location, lhs[i], rhs[i], lhsMLIRTy,
                                        rhsMLIRTy))) {
        return failure();
      }
    }
  }
  return success();
}

/// Nesting check for add/sub: a static-zero scalar is permitted on the lhs
/// (additive identity 0+(x,y)) when @p allowZeroLhs is true, and on the rhs
/// when @p allowZeroRhs is true.
template <typename T>
static LogicalResult
checkArithTupleNestingAddSub(std::optional<Location> location, const T &lhs,
                             const T &rhs, Type lhsMLIRTy, Type rhsMLIRTy,
                             bool allowZeroLhs, bool allowZeroRhs) {
  bool lhsIsLeaf = cg::holds_leaf(lhs);
  bool rhsIsLeaf = cg::holds_leaf(rhs);
  if (lhsIsLeaf && !rhsIsLeaf) {
    if (allowZeroLhs && (lhs == 0)) {
      return success();
    }
    return emitOptionalError(
        location,
        "expects matching structure, but lhs is a scalar and rhs "
        "is a tuple: ",
        lhsMLIRTy, " and ", rhsMLIRTy);
  }
  if (!lhsIsLeaf && rhsIsLeaf) {
    if (allowZeroRhs && (rhs == 0)) {
      return success();
    }
    return emitOptionalError(
        location,
        "expects matching structure, but rhs is a scalar and lhs "
        "is a tuple: ",
        lhsMLIRTy, " and ", rhsMLIRTy);
  }
  if (lhsIsLeaf) { // Both leaves — nothing more to check.
    return success();
  }
  return checkSubElementNesting(location, lhs, rhs, lhsMLIRTy, rhsMLIRTy);
}

//===----------------------------------------------------------------------===//
// TupleAddOp (cute.tuple_add)
//===----------------------------------------------------------------------===//

LogicalResult TupleAddOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  TupleAddOp::Adaptor adaptor(operands, attributes, properties);
  Type lhsTy = adaptor.getLhs().getType();
  Type rhsTy = adaptor.getRhs().getType();
  return llvm::TypeSwitch<Type, LogicalResult>(lhsTy)
      .Case<IntTupleType, ShapeType>([&](auto lhs) -> LogicalResult {
        using LhsTy = std::decay_t<decltype(lhs)>;
        using algebra_t = typename LhsTy::algebra_t;
        auto rhs = llvm::dyn_cast<LhsTy>(rhsTy);
        if (!rhs) {
          return emitOptionalError(location,
                                   "expects lhs and rhs "
                                   "to have the same kind, but got ",
                                   lhsTy, " and ", rhsTy);
        }
        auto nestingResult = checkArithTupleNestingAddSub(
            location, lhs.getRef(), rhs.getRef(), lhsTy, rhsTy,
            /*allowZeroLhs=*/true, /*allowZeroRhs=*/true);
        if (failed(nestingResult)) {
          return nestingResult;
        }
        auto res = cg::arith_tuple_sum<algebra_t>(lhs.getRef(), rhs.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects valid operands, but "
                                   "cannot compute result for ",
                                   lhsTy, " and ", rhsTy);
        }
        inferredReturnTypes.push_back(LhsTy::get(context, res));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to "
                         "IntTupleType|ShapeType");
      });
}

//===----------------------------------------------------------------------===//
// TupleSubOp (cute.tuple_sub)
//===----------------------------------------------------------------------===//

LogicalResult TupleSubOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  TupleSubOp::Adaptor adaptor(operands, attributes, properties);
  Type lhsTy = adaptor.getLhs().getType();
  Type rhsTy = adaptor.getRhs().getType();
  return llvm::TypeSwitch<Type, LogicalResult>(lhsTy)
      .Case<IntTupleType, ShapeType>([&](auto lhs) -> LogicalResult {
        using LhsTy = std::decay_t<decltype(lhs)>;
        using algebra_t = typename LhsTy::algebra_t;
        auto rhs = llvm::dyn_cast<LhsTy>(rhsTy);
        if (!rhs) {
          return emitOptionalError(location,
                                   "expects lhs and rhs "
                                   "to have the same kind, but got ",
                                   lhsTy, " and ", rhsTy);
        }
        auto nestingResult = checkArithTupleNestingAddSub(
            location, lhs.getRef(), rhs.getRef(), lhsTy, rhsTy,
            /*allowZeroLhs=*/false, /*allowZeroRhs=*/true);
        if (failed(nestingResult)) {
          return nestingResult;
        }
        auto res = cg::arith_tuple_sub<algebra_t>(lhs.getRef(), rhs.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects valid operands, but "
                                   "cannot compute result for ",
                                   lhsTy, " and ", rhsTy);
        }
        inferredReturnTypes.push_back(LhsTy::get(context, res));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to "
                         "IntTupleType|ShapeType");
      });
}

//===----------------------------------------------------------------------===//
// ShapeDivOp (cute.shape_div)
//===----------------------------------------------------------------------===//

/// Pre-checks that shape_div(a, b) is valid before calling the computation.
/// Emits a specific error on failure so users know exactly what went wrong.
static LogicalResult
checkShapeDivPreConditions(std::optional<Location> location, const cg::shape &a,
                           const cg::shape &b, Type aTy, Type bTy) {
  // Zero divisor: scalar b == 0.
  if (cg::holds_int(b) && b.as_int() == 0) {
    return emitOptionalError(location,
                             "expects valid operands, but cannot compute "
                             "shape_div for ",
                             aTy, " and ", bTy, ": divisor is zero");
  }

  if (!cg::holds_vector(a) && !cg::holds_vector(b)) {
    // Scalar / scalar: check mutual divisibility.
    if (cg::holds_int(a) && cg::holds_int(b)) {
      auto av = a.as_int(), bv = b.as_int();
      if (av % bv != 0 && bv % av != 0) {
        return emitOptionalError(
            location,
            "expects valid operands, but cannot compute shape_div for ", aTy,
            " and ", bTy, ": ", av, " is not divisible by ", bv, " (neither ",
            av, " % ", bv, " == 0 nor ", bv, " % ", av, " == 0)");
      }
    }
    return success();
  }

  if (cg::holds_vector(a) && cg::holds_vector(b)) {
    // Tuple / tuple: element-wise pre-check.
    for (size_t i = 0; i < std::min(cg::rank(a), cg::rank(b)); ++i) {
      auto r = checkShapeDivPreConditions(location, a[i], b[i], aTy, bTy);
      if (failed(r)) {
        return r;
      }
    }
    return success();
  }

  if (cg::holds_vector(a) && !cg::holds_vector(b)) {
    // Tuple / scalar: sequential consumption — pre-check each step.
    auto bval = b;
    for (size_t i = 0; i < cg::rank(a); ++i) {
      if (failed(checkShapeDivPreConditions(location, a[i], bval, aTy, bTy))) {
        return failure();
      }
      bval = cg::shape_div(bval, cg::product(a[i]));
    }
    return success();
  }

  return success();
}

//===----------------------------------------------------------------------===//
// ShapeDivOp (cute.shape_div)
//===----------------------------------------------------------------------===//

LogicalResult ShapeDivOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  ShapeDivOp::Adaptor adaptor(operands, attributes, properties);
  auto aTy = llvm::dyn_cast<ShapeType>(adaptor.getA().getType());
  if (!aTy) {
    return emitOptionalError(location, "expects a to be !cute.shape, but got ",
                             adaptor.getA().getType());
  }
  auto bTy = llvm::dyn_cast<ShapeType>(adaptor.getB().getType());
  if (!bTy) {
    return emitOptionalError(location, "expects b to be !cute.shape, but got ",
                             adaptor.getB().getType());
  }
  auto r = checkShapeDivPreConditions(location, aTy.getRef(), bTy.getRef(), aTy,
                                      bTy);
  if (failed(r)) {
    return r;
  }
  cg::shape res = cg::shape_div(aTy.getRef(), bTy.getRef());
  if (!cg::is_valid(res)) {
    return emitOptionalError(location,
                             "expects valid operands, but cannot compute "
                             "shape_div for ",
                             aTy, " and ", bTy);
  }
  inferredReturnTypes.push_back(ShapeType::get(context, std::move(res)));
  return success();
}

// Safe to speculate iff b is static and every leaf is non-zero (guards
// division by zero when LICM / hoisting moves the op past a runtime check).
Speculation::Speculatability ShapeDivOp::getSpeculatability() {
  auto bTy = llvm::dyn_cast<ShapeType>(getB().getType());
  bool safe = bTy && isStaticAllLeavesNonZero(bTy);
  return safe ? Speculation::Speculatable : Speculation::NotSpeculatable;
}

//===----------------------------------------------------------------------===//
// CeilDivOp (cute.ceil_div)
//===----------------------------------------------------------------------===//

/// Pre-checks that ceil_div(input, tiler) is valid before calling the
/// computation. Emits a specific error on failure so users know what went
/// wrong.
template <typename TRecVarA, typename TRecVarB>
static LogicalResult checkCeilDivPreConditions(std::optional<Location> location,
                                               const TRecVarA &input,
                                               const TRecVarB &tiler,
                                               Type inputTy, Type tilerTy) {
  // Scalar tiler must not be zero.
  if (!cg::holds_vector(tiler) && cg::holds_int(tiler) && tiler.as_int() == 0) {
    return emitOptionalError(location,
                             "expects valid operands, but cannot compute "
                             "ceil_div for ",
                             inputTy, " and ", tilerTy, ": tiler is zero");
  }

  // Tuple / tuple: rank(tiler) must not exceed rank(input), then check
  // each element pair directly.
  if (cg::holds_vector(input) && cg::holds_vector(tiler)) {
    if (cg::rank(input) < cg::rank(tiler)) {
      return emitOptionalError(
          location, "expects valid operands, but cannot compute ceil_div for ",
          inputTy, " and ", tilerTy, ": rank(tiler)=", cg::rank(tiler),
          " > rank(input)=", cg::rank(input));
    }
    for (size_t i = 0; i < cg::rank(tiler); ++i) {
      if (!cg::is_valid(cg::ceil_div(input[i], tiler[i]))) {
        return emitOptionalError(
            location,
            "expects valid operands, but cannot compute ceil_div for ", inputTy,
            " and ", tilerTy);
      }
    }
    return success();
  }

  // Tuple / scalar: sequential consumption — check each step directly.
  if (cg::holds_vector(input) && !cg::holds_vector(tiler)) {
    auto cur_tiler = tiler;
    for (size_t i = 0; i < cg::rank(input); ++i) {
      if (!cg::is_valid(cg::ceil_div(input[i], cur_tiler))) {
        return emitOptionalError(
            location,
            "expects valid operands, but cannot compute ceil_div for ", inputTy,
            " and ", tilerTy);
      }
      cur_tiler = cg::ceil_div(cur_tiler, input[i]);
    }
    return success();
  }

  return success();
}

LogicalResult CeilDivOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  CeilDivOp::Adaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();
  Type tilerTyVal = adaptor.getTiler().getType();
  // Bridge int_tuple -> shape -> int_tuple when tiler is tile:
  // cg::ceil_div has no (int_tuple, tile) overload because
  // scalar_ceil_div_visitor doesn't cover layout_t / underscore_t
  // alternatives inside cute_tile_t.
  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<IntTupleType, ShapeType>([&](auto input) -> LogicalResult {
        using InputTy = std::decay_t<decltype(input)>;
        return llvm::TypeSwitch<Type, LogicalResult>(tilerTyVal)
            .Case<IntTupleType, ShapeType>([&](auto tiler) -> LogicalResult {
              auto divPreConditionsResult = checkCeilDivPreConditions(
                  location, input.getRef(), tiler.getRef(), inputTy,
                  tilerTyVal);
              if (failed(divPreConditionsResult)) {
                return divPreConditionsResult;
              }
              auto res = cg::ceil_div(input.getRef(), tiler.getRef());
              if (!cg::is_valid(res)) {
                return emitOptionalError(
                    location,
                    "expects valid operands, but cannot compute "
                    "ceil_div for ",
                    inputTy, " and ", tilerTyVal);
              }
              inferredReturnTypes.push_back(
                  InputTy::get(context, std::move(res)));
              return success();
            })
            .template Case<TileType>([&](TileType tiler) -> LogicalResult {
              // Bridge through shape so the (int_tuple, tile) case
              // hits cutegen's defined ceil_div(shape, tile) overload.
              // Tile can't be a scalar int, so the
              // checkCeilDivPreConditions scalar-zero check doesn't
              // instantiate — rely on cg::is_valid to surface any
              // failure (rank mismatch, divisibility, ...).
              auto inputAsShape = cg::rec_var_cast<cg::shape>(input.getRef());
              auto resShape = cg::ceil_div(inputAsShape, tiler.getRef());
              if (!cg::is_valid(resShape)) {
                return emitOptionalError(
                    location,
                    "expects valid operands, but cannot compute "
                    "ceil_div for ",
                    inputTy, " and ", tilerTyVal);
              }
              if constexpr (std::is_same_v<InputTy, IntTupleType>) {
                inferredReturnTypes.push_back(IntTupleType::get(
                    context, cg::rec_var_cast<cg::int_tuple>(resShape)));
              } else {
                inferredReturnTypes.push_back(
                    ShapeType::get(context, std::move(resShape)));
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

// Safe to speculate iff tiler is static and every leaf is non-zero (guards
// division by zero when LICM / hoisting moves the op past a runtime check).
// Tile-typed tiler is conservatively never speculatable.
Speculation::Speculatability CeilDivOp::getSpeculatability() {
  bool safe = llvm::TypeSwitch<Type, bool>(getTiler().getType())
                  .Case<IntTupleType, ShapeType>(
                      [](auto ty) { return isStaticAllLeavesNonZero(ty); })
                  .Default([](Type) { return false; });
  return safe ? Speculation::Speculatable : Speculation::NotSpeculatable;
}

//===----------------------------------------------------------------------===//
// ElemLessOp (cute.elem_less)
//===----------------------------------------------------------------------===//

LogicalResult ElemLessOp::verify() {
  Type lhsTy = getLhs().getType();
  Type rhsTy = getRhs().getType();
  bool congruent =
      llvm::TypeSwitch<Type, bool>(lhsTy)
          .Case<IntTupleType, ShapeType, CoordType>([&](auto lhs) {
            return llvm::TypeSwitch<Type, bool>(rhsTy)
                .Case<IntTupleType, ShapeType, CoordType>([&](auto rhs) {
                  return cg::is_congruent(lhs.getRef(), rhs.getRef());
                })
                .Default([](Type) { return false; });
          })
          .Default([](Type) { return false; });
  if (!congruent) {
    return emitOpError() << "expects congruent inputs, but got " << lhsTy
                         << " and " << rhsTy;
  }
  return success();
}

//===----------------------------------------------------------------------===//
// EqualOp (cute.equal)
//===----------------------------------------------------------------------===//

LogicalResult EqualOp::verify() {
  // Operand kind support is enforced by Cute_EqualOperandType in ODS
  // ({IntTuple, Shape, Coord, Stride, Layout}); only the same-kind
  // constraint remains here. Cross-kind comparison is rejected even
  // when the underlying profiles look similar.
  Type lhsTy = getLhs().getType();
  Type rhsTy = getRhs().getType();
  bool sameKind =
      llvm::TypeSwitch<Type, bool>(lhsTy)
          .Case<IntTupleType, ShapeType, CoordType, StrideType, LayoutType>(
              [&](auto lhs) {
                return llvm::isa<std::decay_t<decltype(lhs)>>(rhsTy);
              })
          .Default([](Type) { return false; });
  if (!sameKind) {
    return emitOpError() << "expects lhs and rhs to be the same kind, but got "
                         << lhsTy << " and " << rhsTy;
  }
  return success();
}

//===----------------------------------------------------------------------===//
// Product ops' helpers (LogicalProduct, ZippedProduct, TiledProduct,
//              FlatProduct, RakedProduct, BlockedProduct)
//===----------------------------------------------------------------------===//

/// Shared inferReturnTypes body for layout binary ops (product family).
/// @p callCutegen is a lambda (auto inputRef, auto tilerRef) -> result_type
/// that calls the appropriate cutegen function.
template <typename OpAdaptor, typename CallCutegen>
static LogicalResult inferLayoutBinaryReturnTypes(
    MLIRContext *context, std::optional<Location> location, OpAdaptor &adaptor,
    SmallVectorImpl<Type> &inferredReturnTypes, CallCutegen &&callCutegen) {
  Type lhsTy = adaptor.getLhs().getType();
  return llvm::TypeSwitch<Type, LogicalResult>(lhsTy)
      .Case<LayoutType, ComposedLayoutType>([&](auto lhsLay) -> LogicalResult {
        using LhsClass = std::decay_t<decltype(lhsLay)>;
        // Reject any non-static lhs (stricter than cutegen, which
        // accepts rank-1 dyn-stride layouts in its 2-arg complement).
        bool lhsStatic;
        if constexpr (std::is_same_v<LhsClass, ComposedLayoutType>) {
          lhsStatic = cg::is_static(lhsLay.getRef().layout_b());
        } else {
          lhsStatic = cg::is_static(lhsLay.getRef());
        }
        if (!lhsStatic) {
          return emitOptionalError(location,
                                   "expects lhs to be static, but got ", lhsTy);
        }
        auto rhsTy = llvm::dyn_cast<LayoutType>(adaptor.getRhs().getType());
        if (!rhsTy) {
          return emitOptionalError(location,
                                   "expects rhs to be !cute.layout, but got ",
                                   adaptor.getRhs().getType());
        }
        // Reject scaled-basis stride on rhs upfront — composition
        // (called downstream of complement(lhs)) rejects it anyway,
        // but with a generic cannot-compute-product sentinel. No
        // rank-1 dyn-stride restriction here: product doesn't call
        // complement on rhs (divide does).
        if (!cg::is_int_or_dynamic_int_only(rhsTy.getRef().stride())) {
          return emitOptionalError(
              location,
              "expects rhs stride to be integer-only "
              "(scaled-basis strides like `N@M` are not supported), "
              "but got ",
              rhsTy);
        }
        // Require static rhs when lhs has scaled-basis strides.
        bool lhsHasSB;
        if constexpr (std::is_same_v<LhsClass, ComposedLayoutType>) {
          lhsHasSB = !cg::is_int_or_dynamic_int_only(
              lhsLay.getRef().layout_b().stride());
        } else {
          lhsHasSB = !cg::is_int_or_dynamic_int_only(lhsLay.getRef().stride());
        }
        if (lhsHasSB && !cg::is_static(rhsTy.getRef())) {
          return emitOptionalError(
              location,
              "expects rhs to be static when lhs has scaled-basis "
              "strides (`N@M`), but got rhs ",
              rhsTy);
        }
        auto res = callCutegen(lhsLay.getRef(), rhsTy.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects valid operands, but cannot compute "
                                   "product for ",
                                   lhsTy, " and ", rhsTy);
        }
        inferredReturnTypes.push_back(
            pickNormalOrComposedLayoutType<LhsClass>(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $lhs to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// LogicalProduct (cute.logical_product)
//===----------------------------------------------------------------------===//

LogicalResult LogicalProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::logical_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// ZippedProduct (cute.zipped_product)
//===----------------------------------------------------------------------===//

LogicalResult ZippedProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::zipped_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// TiledProduct (cute.tiled_product)
//===----------------------------------------------------------------------===//

LogicalResult TiledProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::tiled_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// FlatProduct (cute.flat_product)
//===----------------------------------------------------------------------===//

LogicalResult FlatProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::flat_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// RakedProduct (cute.raked_product)
//===----------------------------------------------------------------------===//

LogicalResult RakedProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::raked_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// BlockedProduct (cute.blocked_product)
//===----------------------------------------------------------------------===//

LogicalResult BlockedProductOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferLayoutBinaryReturnTypes(context, location, adaptor,
                                      inferredReturnTypes,
                                      [](auto const &lhs, auto const &rhs) {
                                        return cg::blocked_product(lhs, rhs);
                                      });
}

//===----------------------------------------------------------------------===//
// Divide ops' helpers (LogicalDivide, ZippedDivide, TiledDivide, FlatDivide)
//===----------------------------------------------------------------------===//

/// Pre-checks divide tiler conditions so the user gets a specific diagnostic
/// instead of the generic cannot-compute-divide sentinel. Top-level layout
/// tiler scaled-basis strides are delegated to cutegen. Layout components
/// nested inside a tile still reject scaled-basis strides. Composition's joint
/// input/tiler preconditions are left to the is_valid(res) sentinel after the
/// divide call (see
/// @scaled_basis_input_layout_tiler_sentinel in
/// logical_divide_errors.mlir).
///
/// path accumulates the mode indices walked from the outer tile when
/// called recursively from checkDivideTilerTile; appended to the
/// diagnostic as " at mode path [...]".
static LogicalResult checkDivideTilerLayout(
    std::optional<Location> location, const cg::layout &tilerLayout,
    SmallVectorImpl<size_t> *path = nullptr, bool isTileType = false) {
  SmallString<64> pathSuffix;
  if (path && !path->empty()) {
    llvm::raw_svector_ostream os(pathSuffix);
    os << " at mode path [";
    llvm::interleaveComma(*path, os);
    os << "]";
  }
  if (isTileType && !cg::is_int_or_dynamic_int_only(tilerLayout.stride())) {
    return emitOptionalError(
        location,
        "expects layout components of a tile tiler to have integer-only "
        "strides (scaled-basis strides like `N@M` are not supported), "
        "but got tiler ",
        cutegen::to_string(tilerLayout), StringRef(pathSuffix));
  }
  if (!cg::is_static(tilerLayout.stride()) && cg::rank(tilerLayout) > 1) {
    return emitOptionalError(
        location,
        "expects tiler to have a static stride or to be rank-1, "
        "but got tiler ",
        cutegen::to_string(tilerLayout), StringRef(pathSuffix));
  }
  return success();
}

/// Recursively walks a divide-op tile tiler and applies
/// checkDivideTilerLayout to every layout sub-component.
/// Underscore (_) leaves are skipped — they impose no constraint.
/// path accumulates the mode indices traversed; the diagnostic
/// reports the path to the offending component.
static LogicalResult checkDivideTilerTile(std::optional<Location> location,
                                          const cg::tile &t,
                                          SmallVectorImpl<size_t> &path) {
  if (cg::holds_vector(t)) {
    auto n = cg::rank(t);
    for (size_t i = 0; i < n; ++i) {
      path.push_back(i);
      auto result = checkDivideTilerTile(location, t[i], path);
      path.pop_back();
      if (failed(result)) {
        return result;
      }
    }
    return success();
  }
  // Leaf: either a layout or an underscore.
  if (std::holds_alternative<cg::layout>(t)) {
    // This is a tile type pass isTileType = true to forbid scaled-basis
    // strides.
    return checkDivideTilerLayout(location, std::get<cg::layout>(t), &path,
                                  /*isTileType=*/true);
  }
  // underscore — no constraint.
  return success();
}

/// Shared inferReturnTypes body for the four layout-divide ops.
/// The tiler operand may be a LayoutType, TileType, or ShapeType;
/// all three map to corresponding cutegen overloads of the divide function.
template <typename OpAdaptor, typename CallCutegen>
static LogicalResult inferDivideReturnTypes(
    MLIRContext *context, std::optional<Location> location, OpAdaptor &adaptor,
    SmallVectorImpl<Type> &inferredReturnTypes, CallCutegen &&callCutegen) {
  Type inputTy = adaptor.getInput().getType();
  Type tilerTy = adaptor.getTiler().getType();
  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<LayoutType, ComposedLayoutType>([&](auto inputLay)
                                                -> LogicalResult {
        using InputTy = std::decay_t<decltype(inputLay)>;
        auto doCompute = [&](auto const &tilerRef) -> LogicalResult {
          auto res = callCutegen(inputLay.getRef(), tilerRef);
          // Residual sentinel: cutegen's composition runs stride- and
          // depth-aware weak divisibility checks
          // (cutegen/layout.hpp) that cannot be reliably
          // pre-checked at this layer without duplicating the walking
          // algorithm. Shape/tile tilers never trigger these (cutegen
          // over-sizes gracefully via ceil_div); only layout tilers
          // can. The two pinned residual cases in
          // logical_divide_errors.mlir
          // (@scaled_basis_input_layout_tiler_sentinel,
          // @static_input_layout_tiler_composition_sentinel) document
          // the surviving paths.
          if (!cg::is_valid(res)) {
            return emitOptionalError(location,
                                     "expects valid operands, but cannot "
                                     "compute divide for ",
                                     inputTy, " and ", tilerTy);
          }
          inferredReturnTypes.push_back(
              pickNormalOrComposedLayoutType<InputTy>(context, std::move(res)));
          return success();
        };
        // Rank guard: when the tiler is a shape or a tile (anything
        // other than a layout), its rank must not exceed the input's
        // rank. For composed input, rank() refers to the B-layout.
        size_t inputRank;
        if constexpr (std::is_same_v<InputTy, ComposedLayoutType>) {
          inputRank = cg::rank(inputLay.getRef().layout_b());
        } else {
          inputRank = cg::rank(inputLay.getRef());
        }
        auto checkRank = [&](size_t tilerRank) -> LogicalResult {
          if (tilerRank > inputRank) {
            return emitOptionalError(
                location, "expects rank(tiler) <= rank(input), but got rank ",
                tilerRank, " tiler and rank ", inputRank, " input");
          }
          return success();
        };
        return llvm::TypeSwitch<Type, LogicalResult>(tilerTy)
            .template Case<LayoutType>([&](LayoutType t) -> LogicalResult {
              // Layout tilers are not rank-checked: cutegen's
              // composition handles rank > input for layouts. But the
              // layout itself is fed to complement (see
              // cutegen/layout.hpp), so its stride must satisfy
              // complement's preconditions — pre-checked upfront for
              // a specific diagnostic.
              auto layoutResult = checkDivideTilerLayout(location, t.getRef());
              if (failed(layoutResult)) {
                return layoutResult;
              }
              return doCompute(t.getRef());
            })
            .template Case<TileType>([&](TileType t) -> LogicalResult {
              auto rankResult = checkRank(cg::rank(t.getRef()));
              if (failed(rankResult)) {
                return rankResult;
              }
              // Tile tilers can contain layout sub-components at any
              // depth. Each layout component is fed to cutegen's
              // complement (via per-mode product_divide), so the
              // same preconditions apply.
              SmallVector<size_t, 4> path;
              auto checkResult =
                  checkDivideTilerTile(location, t.getRef(), path);
              if (failed(checkResult)) {
                return checkResult;
              }
              return doCompute(t.getRef());
            })
            .template Case<ShapeType>([&](ShapeType t) -> LogicalResult {
              auto rankResult = checkRank(cg::rank(t.getRef()));
              if (failed(rankResult)) {
                return rankResult;
              }
              return doCompute(t.getRef());
            })
            .Default([](Type) -> LogicalResult {
              llvm_unreachable("ODS constrains $tiler to "
                               "LayoutType|TileType|ShapeType");
            });
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// LogicalDivide (cute.logical_divide)
//===----------------------------------------------------------------------===//

LogicalResult LogicalDivideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferDivideReturnTypes(context, location, adaptor, inferredReturnTypes,
                                [](auto const &input, auto const &tiler) {
                                  return cg::logical_divide(input, tiler);
                                });
}

//===----------------------------------------------------------------------===//
// ZippedDivide (cute.zipped_divide)
//===----------------------------------------------------------------------===//

LogicalResult ZippedDivideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferDivideReturnTypes(context, location, adaptor, inferredReturnTypes,
                                [](auto const &input, auto const &tiler) {
                                  return cg::zipped_divide(input, tiler);
                                });
}

//===----------------------------------------------------------------------===//
// TiledDivide (cute.tiled_divide)
//===----------------------------------------------------------------------===//

LogicalResult TiledDivideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferDivideReturnTypes(context, location, adaptor, inferredReturnTypes,
                                [](auto const &input, auto const &tiler) {
                                  return cg::tiled_divide(input, tiler);
                                });
}

//===----------------------------------------------------------------------===//
// FlatDivide (cute.flat_divide)
//===----------------------------------------------------------------------===//

LogicalResult FlatDivideOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  return inferDivideReturnTypes(context, location, adaptor, inferredReturnTypes,
                                [](auto const &input, auto const &tiler) {
                                  return cg::flat_divide(input, tiler);
                                });
}

//===----------------------------------------------------------------------===//
// TileToShapeOp (cute.tile_to_shape)
//===----------------------------------------------------------------------===//

LogicalResult TileToShapeOp::inferReturnTypes(
    MLIRContext *context, std::optional<Location> location, ValueRange operands,
    DictionaryAttr attributes, PropertyRef properties, RegionRange /*regions*/,
    SmallVectorImpl<Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties);
  Type inputTy = adaptor.getInput().getType();
  auto shapeTy = llvm::dyn_cast<ShapeType>(adaptor.getShape().getType());
  if (!shapeTy) {
    return emitOptionalError(location,
                             "expects shape to be !cute.shape, but got ",
                             adaptor.getShape().getType());
  }

  // Validate optional $order operand. The dialect requires order to be:
  //   (1) static — every leaf is a compile-time integer,
  //   (2) rank-matched with the target shape, and
  //   (3) a strict 0-based permutation of [0, rank($shape)) — each
  //       index in that half-open interval appears exactly once.
  // (3) is stricter than cutegen, which accepts arbitrary sort-key tuples;
  // the dialect contract is the stronger form to keep $order user-
  // predictable and self-documenting.
  const cg::int_tuple *orderRef = nullptr;
  if (Value orderVal = adaptor.getOrder()) {
    auto orderTy = llvm::dyn_cast<IntTupleType>(orderVal.getType());
    if (!orderTy) {
      return emitOptionalError(location,
                               "expects order to be !cute.int_tuple, but got ",
                               orderVal.getType());
    }
    if (!cg::is_static(orderTy.getRef())) {
      return emitOptionalError(location, "expects static order, but got ",
                               cutegen::to_string(orderTy.getRef()));
    }
    auto orderRank = cg::rank(orderTy.getRef());
    auto shapeRank = cg::rank(shapeTy.getRef());
    if (orderRank != shapeRank) {
      return emitOptionalError(location, "expects order rank (", orderRank,
                               ") to equal target-shape rank (", shapeRank,
                               ")");
    }
    llvm::SmallVector<bool, 8> seen(shapeRank, false);
    for (size_t i = 0; i < shapeRank; ++i) {
      auto leaf = cg::get(orderTy.getRef(), i);
      if (!cg::holds_int(leaf)) {
        return emitOptionalError(
            location, "expects $order to be a permutation of [0, ", shapeRank,
            "), but mode ", i, " is not a static integer");
      }
      int64_t idx = leaf.as_int64();
      if (idx < 0 || idx >= static_cast<int64_t>(shapeRank)) {
        return emitOptionalError(
            location, "expects $order to be a permutation of [0, ", shapeRank,
            "), but got out-of-range index ", idx, " at mode ", i);
      }
      if (seen[idx]) {
        return emitOptionalError(
            location, "expects $order to be a permutation of [0, ", shapeRank,
            "), but index ", idx, " appears more than once");
      }
      seen[idx] = true;
    }
    orderRef = &orderTy.getRef();
  }

  return llvm::TypeSwitch<Type, LogicalResult>(inputTy)
      .Case<LayoutType, ComposedLayoutType>([&](auto inputLay)
                                                -> LogicalResult {
        auto blockRank = cg::rank(inputLay.getRef());
        auto shapeRank = cg::rank(shapeTy.getRef());
        if (blockRank > shapeRank) {
          return emitOptionalError(
              location,
              "expects block layout rank <= target shape rank, but got rank ",
              blockRank, " block and rank ", shapeRank, " target shape");
        }
        auto res = orderRef
                       ? cg::tile_to_shape(inputLay.getRef(), shapeTy.getRef(),
                                           *orderRef)
                       : cg::tile_to_shape(inputLay.getRef(), shapeTy.getRef());
        if (!cg::is_valid(res)) {
          return emitOptionalError(location,
                                   "expects valid operands, but cannot compute "
                                   "tile_to_shape for ",
                                   inputTy, " and ", shapeTy);
        }
        using TyClass = std::decay_t<decltype(inputLay)>;
        inferredReturnTypes.push_back(
            pickNormalOrComposedLayoutType<TyClass>(context, std::move(res)));
        return success();
      })
      .Default([](Type) -> LogicalResult {
        llvm_unreachable("ODS constrains $input to "
                         "LayoutType|ComposedLayoutType");
      });
}

//===----------------------------------------------------------------------===//
// TableGen'd op method definitions
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteOps.cpp.inc"
