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

//===----------------------------------------------------------------------===//
//
// cute-to-base — full dialect conversion from the post-cute-expand-ops
// surviving cute ops (cute.static, cute.get_scalars, the 7 make_*
// constructors, cute.print) to arith / scf / ub / LLVM / gpu. Function
// signatures are converted in the same pass, so the output is fully
// cute-free in both ops and types.
//
//===----------------------------------------------------------------------===//

#include "cute_ir/Conversion/CuteToBase/CuteTypeConverter.h"
#include "cute_ir/Conversion/CuteToBase/Passes.h"
#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"

#include "cutegen/cutegen_mlir.hpp"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Func/Transforms/FuncConversions.h"
#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/UB/IR/UBOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/DialectConversion.h"

#include "llvm/Support/FormatVariadic.h"

namespace mlir::cutlass_compiler::cute {
#define GEN_PASS_DEF_CUTETOBASE
#include "cute_ir/Conversion/CuteToBase/Passes.h.inc"
} // namespace mlir::cutlass_compiler::cute

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
namespace cg = cutegen;

namespace {

//===----------------------------------------------------------------------===//
// StaticOp (cute.static)
//===----------------------------------------------------------------------===//

/// cute.static carries no runtime data — every static value lives in the
/// type signature. Replace with ub.poison of the converted (LLVM struct)
/// type; downstream consumers that need a concrete leaf value extract it
/// via cute.get_scalars, which constant-folds static slots into
/// arith.constant ops.
struct StaticOpConversion final : public OpConversionPattern<StaticOp> {
  using OpConversionPattern<StaticOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(StaticOp op, OpAdaptor /*adaptor*/,
                  ConversionPatternRewriter &rewriter) const override {
    Type loweredTy = getTypeConverter()->convertType(op.getType());
    if (!loweredTy) {
      return rewriter.notifyMatchFailure(op, "type conversion failed");
    }
    rewriter.replaceOpWithNewOp<ub::PoisonOp>(op, loweredTy);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// GetScalarsOp (cute.get_scalars)
//===----------------------------------------------------------------------===//

/// cute.get_scalars extracts the integer leaves of a cute value. After
/// type conversion the value is an LLVM struct (sparse_flat: only dynamic
/// leaves materialize as fields). cutegen's `collect_scalar_values` emits
/// `llvm.extractvalue` for each dynamic field plus `arith.constant` for
/// each static leaf when `only_dynamic=false`.
struct GetScalarsOpConversion final : public OpConversionPattern<GetScalarsOp> {
  using OpConversionPattern<GetScalarsOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(GetScalarsOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Location loc = op.getLoc();
    Type cuteTy = op.getCuteValue().getType();
    Value loweredVal = adaptor.getCuteValue();
    bool onlyDynamic = static_cast<bool>(op.getOnlyDynamic());

    SmallVector<Value> scalars;
    auto collect = [&](auto cgRef) {
      cg::collect_scalar_values(rewriter, loc, cgRef, loweredVal, scalars,
                                onlyDynamic);
    };
    LogicalResult kindMatch =
        llvm::TypeSwitch<Type, LogicalResult>(cuteTy)
            .Case<ShapeType, StrideType, IntTupleType, CoordType, TileType,
                  LayoutType, ComposedLayoutType>([&](auto ty) {
              collect(ty.getRef());
              return success();
            })
            .Case<SwizzleType>([&](SwizzleType ty) {
              // Per cute.get_scalars ODS: a swizzle yields three i32
              // results (num_bits, num_base, num_shift) — all
              // compile-time facts in the type signature. With
              // only_dynamic set, the swizzle has no dynamic leaves and
              // the op returns zero results.
              if (onlyDynamic) {
                return success();
              }
              const auto &sw = ty.getRef();
              Type i32Ty = rewriter.getI32Type();
              scalars.push_back(arith::ConstantOp::create(
                  rewriter, loc, i32Ty,
                  rewriter.getI32IntegerAttr(
                      static_cast<int32_t>(sw.num_bits()))));
              scalars.push_back(arith::ConstantOp::create(
                  rewriter, loc, i32Ty,
                  rewriter.getI32IntegerAttr(
                      static_cast<int32_t>(sw.num_base()))));
              scalars.push_back(arith::ConstantOp::create(
                  rewriter, loc, i32Ty,
                  rewriter.getI32IntegerAttr(sw.num_shift())));
              return success();
            })
            .Default([&](Type ty) {
              return rewriter.notifyMatchFailure(
                  op,
                  llvm::formatv("unsupported get_scalars input type {0}", ty));
            });
    if (failed(kindMatch)) {
      return failure();
    }
    rewriter.replaceOp(op, scalars);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Constructor ops (5 simple + make_layout + make_composed_layout)
//===----------------------------------------------------------------------===//

/// Generic lowering for the 5 simple constructor ops (make_int_tuple,
/// make_shape, make_stride, make_coord, make_tile). Each carries a
/// variadic $operands list of dynamic integer leaves and produces a
/// rec-var-backed cute type. cutegen's cg::build_value walks the result's
/// cute ref and emits llvm.insertvalue for each dynamic leaf, picking up
/// the operand values left-to-right in profile order.
template <typename Op>
struct MakeOpConversion final : public OpConversionPattern<Op> {
  using OpConversionPattern<Op>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(Op op, typename Op::Adaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    const auto &recvar = op.getResult().getType().getRef();
    Value llvmValue =
        cg::build_value(rewriter, op.getLoc(), recvar, adaptor.getOperands());
    rewriter.replaceOp(op, llvmValue);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// MakeShapeOp (cute.make_shape)
//===----------------------------------------------------------------------===//
using MakeShapeOpConversion = MakeOpConversion<MakeShapeOp>;

//===----------------------------------------------------------------------===//
// MakeStrideOp (cute.make_stride)
//===----------------------------------------------------------------------===//
using MakeStrideOpConversion = MakeOpConversion<MakeStrideOp>;

//===----------------------------------------------------------------------===//
// MakeIntTupleOp (cute.make_int_tuple)
//===----------------------------------------------------------------------===//
using MakeIntTupleOpConversion = MakeOpConversion<MakeIntTupleOp>;

//===----------------------------------------------------------------------===//
// MakeCoordOp (cute.make_coord)
//===----------------------------------------------------------------------===//
using MakeCoordOpConversion = MakeOpConversion<MakeCoordOp>;

//===----------------------------------------------------------------------===//
// MakeTileOp (cute.make_tile)
//===----------------------------------------------------------------------===//
using MakeTileOpConversion = MakeOpConversion<MakeTileOp>;

//===----------------------------------------------------------------------===//
// MakeLayoutOp (cute.make_layout)
//===----------------------------------------------------------------------===//

/// cute.make_layout — explicit shape + stride. Build a poison layout
/// struct and set each field from the corresponding operand.
struct MakeLayoutOpConversion final : public OpConversionPattern<MakeLayoutOp> {
  using OpConversionPattern<MakeLayoutOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MakeLayoutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    const auto &layout = op.getLayout().getType().getRef();
    Value layoutVal = cg::make_poison(rewriter, loc, layout);
    layoutVal =
        cg::set_layout_shape(rewriter, loc, layoutVal, adaptor.getShape());
    layoutVal =
        cg::set_layout_stride(rewriter, loc, layoutVal, adaptor.getStride());
    rewriter.replaceOp(op, layoutVal);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// MakeComposedLayoutOp (cute.make_composed_layout)
//===----------------------------------------------------------------------===//

/// cute.make_composed_layout — three explicit operands (inner, offset,
/// outer). Build a poison composed-layout struct and then set each field.
struct MakeComposedLayoutOpConversion final
    : public OpConversionPattern<MakeComposedLayoutOp> {
  using OpConversionPattern<MakeComposedLayoutOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(MakeComposedLayoutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto loc = op.getLoc();
    const auto &layout = op.getResult().getType().getRef();
    Value layoutVal = cg::make_poison(rewriter, loc, layout);
    layoutVal = cg::set_composed_layout_outer(rewriter, loc, layoutVal,
                                              adaptor.getOuter());
    layoutVal = cg::set_composed_layout_offset(rewriter, loc, layoutVal,
                                               adaptor.getOffset());
    layoutVal = cg::set_composed_layout_inner(rewriter, loc, layoutVal,
                                              adaptor.getInner());
    rewriter.replaceOp(op, layoutVal);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// PrintOp (cute.print)
//===----------------------------------------------------------------------===//

/// Build the printf format string from cutegen::to_string(recvar) by
/// replacing each ? (and any trailing {...} annotation) with the
/// per-leaf format specifier from @p scalarTypes. Static parts of the cutegen
/// canonical form (numbers, parens, colons, basis @N, underscore, etc.)
/// pass through unchanged.
static std::string buildFormatStr(StringRef canonical,
                                  ArrayRef<Type> scalarTypes) {
  std::string out;
  out.reserve(canonical.size() + scalarTypes.size() * 4);
  size_t dynIdx = 0;
  for (size_t i = 0; i < canonical.size() && dynIdx <= scalarTypes.size();) {
    if (canonical[i] != '?') {
      out.push_back(canonical[i]);
      ++i;
      continue;
    }
    // Format specifier per dynamic-leaf width.
    unsigned width = scalarTypes[dynIdx].getIntOrFloatBitWidth();
    out += (width == 64 ? "%lld" : "%d");
    ++dynIdx;
    ++i;
    // Skip an optional {...} annotation hints in the cutegen-printed form).
    if (i < canonical.size() && canonical[i] == '{') {
      int depth = 1;
      ++i;
      while (i < canonical.size() && depth > 0) {
        if (canonical[i] == '{') {
          ++depth;
        } else if (canonical[i] == '}') {
          --depth;
        }
        ++i;
      }
    }
  }

  assert(dynIdx == scalarTypes.size() &&
         "scalarTypes / canonical-?-count mismatch");

  return out;
}

/// Returns the LLVM function type for printf: i32 (ptr, ...).
static LLVM::LLVMFunctionType getPrintfType(MLIRContext *context) {
  auto i32Ty = IntegerType::get(context, 32);
  auto ptrTy = LLVM::LLVMPointerType::get(context);
  return LLVM::LLVMFunctionType::get(i32Ty, ptrTy, /*isVarArg=*/true);
}

/// Inserts an llvm.func @printf declaration into @p module if not already
/// present, and returns a FlatSymbolRefAttr referring to it.
static FlatSymbolRefAttr getOrInsertPrintf(PatternRewriter &rewriter,
                                           ModuleOp module) {
  MLIRContext *context = module.getContext();
  if (module.lookupSymbol<LLVM::LLVMFuncOp>("printf")) {
    return SymbolRefAttr::get(context, "printf");
  }
  PatternRewriter::InsertionGuard guard(rewriter);
  rewriter.setInsertionPointToStart(module.getBody());
  LLVM::LLVMFuncOp::create(rewriter, module.getLoc(), "printf",
                           getPrintfType(context));
  return SymbolRefAttr::get(context, "printf");
}

/// Returns a unique global symbol name (printfFormat_<N>) within @p module.
static SmallString<16> getUniqueFormatGlobalName(ModuleOp module) {
  unsigned n = 0;
  SmallString<16> name;
  do {
    name.clear();
    ("printfFormat_" + Twine(n++)).toStringRef(name);
  } while (module.lookupSymbol(name));
  return name;
}

/// Materializes a null-terminated format string as an llvm.mlir.global
/// (private constant) and returns a ptr to its first character. The
/// global is inserted at the top of @p module.
static Value getOrCreateGlobalString(Location loc, OpBuilder &builder,
                                     StringRef name, StringRef value,
                                     ModuleOp module) {
  MLIRContext *context = builder.getContext();
  LLVM::GlobalOp global = module.lookupSymbol<LLVM::GlobalOp>(name);
  if (!global) {
    OpBuilder::InsertionGuard guard(builder);
    builder.setInsertionPointToStart(module.getBody());
    auto strTy =
        LLVM::LLVMArrayType::get(IntegerType::get(context, 8), value.size());
    global = LLVM::GlobalOp::create(builder, loc, strTy, /*isConstant=*/true,
                                    LLVM::Linkage::Internal, name,
                                    builder.getStringAttr(value),
                                    /*alignment=*/0);
  }
  Value addr = LLVM::AddressOfOp::create(builder, loc, global);
  Value zero =
      arith::ConstantOp::create(builder, loc, builder.getI64IntegerAttr(0));
  return LLVM::GEPOp::create(builder, loc, LLVM::LLVMPointerType::get(context),
                             global.getType(), addr,
                             ArrayRef<Value>{zero, zero});
}

/// cute.print — emits a runtime dump of the operand's value. The format
/// string mirrors cutegen's canonical printed form with each ? replaced
/// by %d or %lld based on width; dynamic leaves are passed as
/// arguments. Lowers to gpu.printf inside a GPU module/launch; otherwise
/// to llvm.call @printf (with a generated llvm.mlir.global format string).
struct PrintOpConversion final : public OpConversionPattern<PrintOp> {
  using OpConversionPattern<PrintOp>::OpConversionPattern;

  LogicalResult
  matchAndRewrite(PrintOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Location loc = op.getLoc();
    Type cuteTy = op.getValue().getType();
    Value loweredVal = adaptor.getValue();
    MLIRContext *context = rewriter.getContext();

    std::string fmtStr;
    SmallVector<Value> scalars;

    // Dispatch on the rec-var-backed cute types. cutegen's `to_string`
    // gives the canonical printed form (with `?` for dynamic leaves);
    // `collect_scalar_types` returns the dyn-leaf MLIR types in the
    // same left-to-right order so we can substitute widths into the
    // format string. SwizzleType is special-cased — it has no dynamic
    // leaves, so the canonical string is the entire format.
    {
      [[maybe_unused]] LogicalResult kindMatch =
          llvm::TypeSwitch<Type, LogicalResult>(cuteTy)
              .Case<ShapeType, StrideType, IntTupleType, CoordType, TileType,
                    LayoutType>([&](auto ty) {
                const auto &ref = ty.getRef();
                SmallVector<Type> scalarTypes;
                cg::collect_scalar_types(context, ref, scalarTypes,
                                         /*dynamic_only=*/true);
                fmtStr = buildFormatStr(cg::to_string(ref), scalarTypes);
                cg::collect_scalar_values(rewriter, loc, ref, loweredVal,
                                          scalars, /*onlyDynamic=*/true);
                return success();
              })
              .Case<ComposedLayoutType>([&](ComposedLayoutType ty) {
                // Composed-layout dyn-leaf ordering fix-up: cutegen's
                // to_string emits A o offset o B, but the LLVM struct
                // backing the composed type is laid out as (B, offset, A)
                // at indices (0, 1, 2). Without the fix the printed leaves
                // would land in the wrong slots — e.g. composed
                // (?):(?) o ? o (6,8):(8,1) with leaves (inner_shape=3,
                // inner_stride=1, offset=0) would print as
                // (0):(3) o 1 o (...) instead of (3):(1) o 0 o (...).
                //

                // Extract each sub-value from the (B, offset, A) struct
                // and run collect_scalar_types / collect_scalar_values
                // per component in print order (A → offset → B), so the
                // format string and the scalar args land in the canonical
                // order with no post-collection rotation.
                const auto &ref = ty.getRef();
                Value bVal = cg::get_composed_layout_outer_value(rewriter, loc,
                                                                 loweredVal);
                Value offVal = cg::get_composed_layout_offset_value(
                    rewriter, loc, loweredVal);
                Value aVal = cg::get_composed_layout_inner_value(rewriter, loc,
                                                                 loweredVal);

                SmallVector<Type> aTypes, offTypes, bTypes;
                if (ref.is_a_affine()) {
                  cg::collect_scalar_types(context, ref.layout_a(), aTypes,
                                           /*dynamic_only=*/true);
                }
                // Swizzle A has no dynamic leaves — collect_scalar_types
                // for swizzle is a no-op when dynamic_only=true.
                cg::collect_scalar_types(context, ref.offset(), offTypes,
                                         /*dynamic_only=*/true);
                cg::collect_scalar_types(context, ref.layout_b(), bTypes,
                                         /*dynamic_only=*/true);

                SmallVector<Type> scalarTypes;
                scalarTypes.append(aTypes.begin(), aTypes.end());
                scalarTypes.append(offTypes.begin(), offTypes.end());
                scalarTypes.append(bTypes.begin(), bTypes.end());
                fmtStr = buildFormatStr(cg::to_string(ref), scalarTypes);

                if (ref.is_a_affine()) {
                  cg::collect_scalar_values(rewriter, loc, ref.layout_a(), aVal,
                                            scalars,
                                            /*dynamic_only=*/true);
                }
                cg::collect_scalar_values(rewriter, loc, ref.offset(), offVal,
                                          scalars, /*dynamic_only=*/true);
                cg::collect_scalar_values(rewriter, loc, ref.layout_b(), bVal,
                                          scalars, /*dynamic_only=*/true);
                return success();
              })
              .Case<SwizzleType>([&](SwizzleType ty) {
                fmtStr = cg::to_string(ty.getRef());
                return success();
              })
              .Default([](Type) -> LogicalResult {
                llvm_unreachable(
                    "ODS constrains $value to IntTupleType|CoordType|"
                    "ShapeType|StrideType|LayoutType|TileType|"
                    "ComposedLayoutType|SwizzleType");
              });
      assert(succeeded(kindMatch) &&
             "Default branch is llvm_unreachable; kindMatch is always success");
    }

    // Trailing newline so successive prints don't run together.
    fmtStr.push_back('\n');

    bool inGpu = op->getParentOfType<gpu::GPUModuleOp>() ||
                 op->getParentOfType<gpu::LaunchOp>();

    if (inGpu) {
      gpu::PrintfOp::create(rewriter, loc,
                            /*format=*/StringAttr::get(context, fmtStr),
                            /*args=*/scalars);
      rewriter.eraseOp(op);
      return success();
    }

    ModuleOp module = op->getParentOfType<ModuleOp>();
    if (!module) {
      return rewriter.notifyMatchFailure(
          op, "cute.print on host requires an enclosing builtin.module");
    }
    SmallString<16> globalName = getUniqueFormatGlobalName(module);
    fmtStr.push_back('\0'); // C string termination for printf
    Value fmtPtr =
        getOrCreateGlobalString(loc, rewriter, globalName, fmtStr, module);
    FlatSymbolRefAttr printfRef = getOrInsertPrintf(rewriter, module);

    SmallVector<Value> callArgs;
    callArgs.reserve(scalars.size() + 1);
    callArgs.push_back(fmtPtr);
    callArgs.append(scalars.begin(), scalars.end());
    LLVM::CallOp::create(rewriter, loc, getPrintfType(context), printfRef,
                         callArgs);
    rewriter.eraseOp(op);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Pass driver
//===----------------------------------------------------------------------===//

struct CuteToBasePass
    : public mlir::cutlass_compiler::cute::impl::CuteToBaseBase<
          CuteToBasePass> {
  void runOnOperation() override {
    MLIRContext &context = getContext();

    TypeConverter typeConverter;
    configCuteToBaseTypeConverter(typeConverter);

    ConversionTarget target(context);
    target.addLegalDialect<arith::ArithDialect, scf::SCFDialect, ub::UBDialect,
                           LLVM::LLVMDialect, gpu::GPUDialect>();
    // The whole cute dialect is illegal — every op must lower via a
    // pattern. This is stricter than enumerating ops one-by-one: any new
    // cute op without a pattern will fail conversion loudly here, instead
    // of silently flowing through.
    target.addIllegalDialect<CuteDialect>();
    // Function signatures using cute types must also be converted so the
    // pass output is fully cute-free (no boundary unrealized_conversion_cast
    // ops left at function entry / return). Mark func.func /
    // func.return / func.call dynamically legal only when their
    // signatures are already in the converted form.
    target.addDynamicallyLegalOp<func::FuncOp>([&](func::FuncOp op) {
      return typeConverter.isSignatureLegal(op.getFunctionType()) &&
             typeConverter.isLegal(&op.getBody());
    });
    target.addDynamicallyLegalOp<func::ReturnOp, func::CallOp>(
        [&](Operation *op) { return typeConverter.isLegal(op); });
    target.markUnknownOpDynamicallyLegal([](Operation *) { return true; });

    RewritePatternSet patterns(&context);
    patterns.add<StaticOpConversion, GetScalarsOpConversion,
                 MakeIntTupleOpConversion, MakeShapeOpConversion,
                 MakeStrideOpConversion, MakeCoordOpConversion,
                 MakeTileOpConversion, MakeLayoutOpConversion,
                 MakeComposedLayoutOpConversion, PrintOpConversion>(
        typeConverter, &context);
    // Function signature / return / call conversion using the same cute
    // TypeConverter — eliminates the boundary casts at func entry/return.
    populateFunctionOpInterfaceTypeConversionPattern<func::FuncOp>(
        patterns, typeConverter);
    populateReturnOpTypeConversionPattern(patterns, typeConverter);
    populateCallOpTypeConversionPattern(patterns, typeConverter);

    if (failed(applyPartialConversion(getOperation(), target,
                                      std::move(patterns)))) {
      signalPassFailure();
    }
  }
};

} // namespace
