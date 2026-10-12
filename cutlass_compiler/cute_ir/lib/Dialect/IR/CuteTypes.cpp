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

#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"

#include "llvm/ADT/TypeSwitch.h"

#include <map>

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;

namespace cg = cutegen;

namespace {

/// Returns true when s has both scaled-basis leaves and non-zero integer
/// leaves. Cutegen's stride algebra cannot mix the two kinds — only
/// all-integer or all-scaled-basis (zero integers allowed when mixed)
/// is well-formed. Enforced as a StrideType invariant so the malformed
/// form can never appear in a well-typed IR.
bool hasMixedNonZeroIntAndScaledBasisStrides(cutegen::stride const &s) {
  if (!cutegen::has_scaled_basis(s)) {
    return false;
  }
  using stride_t = cutegen::stride;
  using sb_t = typename cutegen::find_scaled_basis_in_rec_var<stride_t>::value;
  return cutegen::any_leaf_is(s, [](stride_t const &d) {
    return !std::holds_alternative<sb_t>(d) && !(d == 0);
  });
}

/// Returns true when two scaled-basis leaves address the same mode at
/// different depths — i.e. one path terminates at a node another path
/// continues through.
///
/// Examples (paths are the basis modes() vector, outer-to-inner):
///   (1@0, 1@1)         — paths {0}, {1}           — valid ✓
///   (1@0@0, 1@1@0)     — paths {0,0}, {0,1}        — valid ✓
///   (1@1@0, 1@0)       — paths {0,1}, {0}          — invalid ✗
///   ((1@0@0,1@0@1),1@1)— paths {0,0},{1,0},{1}   — invalid ✗
bool hasMixedDepthBasisStrides(cutegen::stride const &s) {
  if (!cutegen::has_scaled_basis(s)) {
    return false;
  }
  using stride_t = cutegen::stride;
  using sb_t = typename cutegen::find_scaled_basis_in_rec_var<stride_t>::value;

  struct Node {
    bool terminal = false;
    std::map<int, Node> children;
  };
  Node root;

  return cutegen::any_leaf_is(s, [&](stride_t const &leaf) {
    if (!std::holds_alternative<sb_t>(leaf)) {
      return false;
    }
    auto const &modes = std::get<sb_t>(leaf).modes();
    if (modes.empty()) {
      return false;
    }
    Node *node = &root;
    for (size_t i = 0; i + 1 < modes.size(); ++i) {
      if (node->terminal) {
        return true;
      }
      node = &node->children[modes[i]];
    }
    if (node->terminal) {
      return true;
    }
    Node &leafNode = node->children[modes.back()];
    if (!leafNode.children.empty()) {
      return true;
    }
    leafNode.terminal = true;
    return false;
  });
}

/// Returns true when any scaled-basis leaf has a ratio value rather than an
/// integer value. Cutegen's stride arithmetic only supports integer-valued
/// scaled-basis. Enforced as a StrideType invariant so the malformed form
/// can never appear in a well-typed IR.
bool hasScaledBasisWithRatioValue(cutegen::stride const &s) {
  if (!cutegen::has_scaled_basis(s)) {
    return false;
  }
  using stride_t = cutegen::stride;
  using sb_t = typename cutegen::find_scaled_basis_in_rec_var<stride_t>::value;
  return cutegen::any_leaf_is(s, [](stride_t const &d) {
    return std::holds_alternative<sb_t>(d) &&
           std::holds_alternative<cutegen::ratio>(std::get<sb_t>(d).value());
  });
}

/// Shared stride-shape verification used by StrideType::verify,
/// LayoutType::verify, and ComposedLayoutType::verify. Returns
/// failure with a diagnostic if s violates either stride invariant.
mlir::LogicalResult
verifyStrideInvariants(llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
                       cutegen::stride const &s) {
  if (hasMixedNonZeroIntAndScaledBasisStrides(s)) {
    return emitError()
           << "expects strides to be either all-integer or all-scaled-basis "
              "(zero integers allowed when mixed), but got \""
           << cutegen::to_string(s) << "\"";
  }
  if (hasScaledBasisWithRatioValue(s)) {
    return emitError()
           << "expects scaled-basis strides to have integer values, "
              "not ratios, but got \""
           << cutegen::to_string(s) << "\"";
  }
  if (hasMixedDepthBasisStrides(s)) {
    return emitError()
           << "expects scaled-basis paths to agree on mode-index depth "
              "(no path may terminate at a node that another path "
              "continues through), but got \""
           << cutegen::to_string(s) << "\"";
  }
  return mlir::success();
}

} // namespace

// Emit the tablegen-generated type storage / parsing machinery (also drives
// CuteDialect::parseType / printType via useDefaultTypePrinterParser).
#define GET_TYPEDEF_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteTypes.cpp.inc"

//===----------------------------------------------------------------------===//
// CuteDialect — type registration
//===----------------------------------------------------------------------===//

void CuteDialect::registerCuteTypes(CuteDialect *dialect) {
  dialect->addTypes<
#define GET_TYPEDEF_LIST
#include "cute_ir/Dialect/Cute/IR/CuteTypes.cpp.inc"
      >();
}

//===----------------------------------------------------------------------===//
// IntTupleType — custom assembly format
//

// Grammar: < " cutegen-int-tuple-string " >
// The string is the cutegen::to_string() serialization; parsing calls
// cutegen::from_string<cutegen::int_tuple>().
//===----------------------------------------------------------------------===//

mlir::Type IntTupleType::parse(mlir::AsmParser &parser) {
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::int_tuple>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse int_tuple from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = IntTupleAttr::get(parser.getContext(), std::move(*opt));
  return IntTupleType::get(parser.getContext(), attr);
}

void IntTupleType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool IntTupleType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute IntTupleType::getValueAttr() const { return getAttr(); }

llvm::TypeSize
IntTupleType::getTypeSize(const mlir::DataLayout &dataLayout,
                          mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
IntTupleType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                                mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t
IntTupleType::getABIAlignment(const mlir::DataLayout &dataLayout,
                              mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
IntTupleType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
IntTupleType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                               mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool IntTupleType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  // The lowering can be a bare integer (scalar/depth-0 dynamic leaves), which
  // does not implement DataLayoutTypeInterface; only delegate when it does and
  // otherwise fall back to the interface default ("compatible").
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
IntTupleType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                            mlir::Location loc) const {
  OpBuilder builder(getContext());
  // See areCompatible: bare-integer lowerings cannot be queried, so only
  // delegate when the lowered type implements the interface.
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// CoordType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type CoordType::parse(mlir::AsmParser &parser) {
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::coord>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse coord from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = CoordAttr::get(parser.getContext(), std::move(*opt));
  return CoordType::get(parser.getContext(), attr);
}

void CoordType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool CoordType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute CoordType::getValueAttr() const { return getAttr(); }

llvm::TypeSize
CoordType::getTypeSize(const mlir::DataLayout &dataLayout,
                       mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
CoordType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                             mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t CoordType::getABIAlignment(const mlir::DataLayout &dataLayout,
                                    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
CoordType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                 mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
CoordType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                            mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool CoordType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
CoordType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                         mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// ShapeType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type ShapeType::parse(mlir::AsmParser &parser) {
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::shape>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse shape from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = ShapeAttr::get(parser.getContext(), std::move(*opt));
  return ShapeType::get(parser.getContext(), attr);
}

void ShapeType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool ShapeType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute ShapeType::getValueAttr() const { return getAttr(); }

llvm::TypeSize
ShapeType::getTypeSize(const mlir::DataLayout &dataLayout,
                       mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
ShapeType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                             mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t ShapeType::getABIAlignment(const mlir::DataLayout &dataLayout,
                                    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
ShapeType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                 mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
ShapeType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                            mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool ShapeType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
ShapeType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                         mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// StrideType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type StrideType::parse(mlir::AsmParser &parser) {
  // Capture the start location so verify() failures are attributed to the
  // type literal.
  auto loc = parser.getCurrentLocation();
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::stride>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse stride from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = StrideAttr::get(parser.getContext(), std::move(*opt));
  return StrideType::getChecked([&] { return parser.emitError(loc); },
                                parser.getContext(), attr);
}

void StrideType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool StrideType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute StrideType::getValueAttr() const { return getAttr(); }

/// Verify StrideType storage invariants. Each check rejects a form that
/// cutegen's stride algebra cannot handle, lifted from per-op
/// inferReturnTypes so the malformed stride can never appear in a
/// well-typed IR:
///   1. No mixed nonzero-integer + scaled-basis leaves.
///   2. No ratio-valued scaled-basis leaves.
///   3. No mixed-depth scaled-basis paths.
mlir::LogicalResult
StrideType::verify(llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
                   StrideAttr attr) {
  return verifyStrideInvariants(emitError, attr.getRef());
}

llvm::TypeSize
StrideType::getTypeSize(const mlir::DataLayout &dataLayout,
                        mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
StrideType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                              mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t
StrideType::getABIAlignment(const mlir::DataLayout &dataLayout,
                            mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
StrideType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                  mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
StrideType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                             mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool StrideType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
StrideType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                          mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// LayoutType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type LayoutType::parse(mlir::AsmParser &parser) {
  // Capture the start location for the verifier diagnostic emitter so a
  // verify() failure (e.g. non-positive shape mode) is attributed to the
  // type literal rather than <unknown>:0.
  auto loc = parser.getCurrentLocation();
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::layout>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse layout from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = LayoutAttr::get(parser.getContext(), std::move(*opt));
  // getChecked routes verifyInvariants() failures through the diagnostic
  // emit fn (returns null on failure) instead of asserting like get().
  return LayoutType::getChecked([&] { return parser.emitError(loc); },
                                parser.getContext(), attr);
}

void LayoutType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool LayoutType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute LayoutType::getValueAttr() const { return getAttr(); }

/// Verify LayoutType storage invariants. cutegen leaves these
/// unchecked at construction time for performance; enforce them at the
/// IR boundary.
mlir::LogicalResult
LayoutType::verify(llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
                   LayoutAttr attr) {
  auto const &layout = attr.getRef();
  if (cutegen::has_error(layout)) {
    return emitError() << "expects no error(`x`) in layout, but got \""
                       << cutegen::to_string(layout) << "\"";
  }
  if (cutegen::any_leaf_is(layout.shape(), [](auto const &e) {
        return cutegen::holds_int(e) && cutegen::get_int(e) <= 0;
      })) {
    return emitError() << "expects positive shape mode, but got \""
                       << cutegen::to_string(layout) << "\"";
  }
  if (!cutegen::is_congruent(layout.shape(), layout.stride())) {
    return emitError()
           << "expects shape and stride profile to match, but got \""
           << cutegen::to_string(layout) << "\"";
  }
  return verifyStrideInvariants(emitError, layout.stride());
}

llvm::TypeSize
LayoutType::getTypeSize(const mlir::DataLayout &dataLayout,
                        mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
LayoutType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                              mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t
LayoutType::getABIAlignment(const mlir::DataLayout &dataLayout,
                            mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
LayoutType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                  mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
LayoutType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                             mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool LayoutType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
LayoutType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                          mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// TileType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type TileType::parse(mlir::AsmParser &parser) {
  // Capture the start location so verify() failures (mixed-depth basis
  // strides inside a layout slot, etc.) attribute to the type literal.
  auto loc = parser.getCurrentLocation();
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::tile>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse tile from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = TileAttr::get(parser.getContext(), std::move(*opt));
  return TileType::getChecked([&] { return parser.emitError(loc); },
                              parser.getContext(), attr);
}

void TileType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool TileType::isStatic() const { return cutegen::is_static(getRef()); }

mlir::Attribute TileType::getValueAttr() const { return getAttr(); }

/// Verify TileType storage invariants. Each layout leaf's stride must
/// satisfy the stride invariants enforced by verifyStrideInvariants.
mlir::LogicalResult
TileType::verify(llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
                 TileAttr attr) {
  auto const &tile = attr.getRef();
  mlir::LogicalResult result = mlir::success();
  cutegen::any_leaf_is(tile, [&](cutegen::tile const &leaf) {
    if (!std::holds_alternative<cutegen::layout>(leaf)) {
      return false;
    }
    auto const &lyt = std::get<cutegen::layout>(leaf);
    auto r = verifyStrideInvariants(emitError, lyt.stride());
    if (mlir::failed(r)) {
      result = r;
      return true;
    }
    return false;
  });
  return result;
}

llvm::TypeSize
TileType::getTypeSize(const mlir::DataLayout &dataLayout,
                      mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize
TileType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                            mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t TileType::getABIAlignment(const mlir::DataLayout &dataLayout,
                                   mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t
TileType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t>
TileType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                           mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool TileType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
TileType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                        mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// ComposedLayoutType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type ComposedLayoutType::parse(mlir::AsmParser &parser) {
  // Capture the start location so verify() failures (positivity,
  // congruence) are attributed to the type literal.
  auto loc = parser.getCurrentLocation();
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::composed_layout>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse composed_layout from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = ComposedLayoutAttr::get(parser.getContext(), std::move(*opt));
  return ComposedLayoutType::getChecked([&] { return parser.emitError(loc); },
                                        parser.getContext(), attr);
}

void ComposedLayoutType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool ComposedLayoutType::isStatic() const {
  // No free cutegen::is_static(composed_layout_t) exists — check each part.
  const auto &cl = getRef();
  bool b_ok = cutegen::is_static(cl.layout_b());
  bool off_ok = cutegen::is_static(cl.offset());
  bool a_ok = cl.is_a_swizzle() || cutegen::is_static(cl.layout_a());
  return b_ok && off_ok && a_ok;
}

mlir::Attribute ComposedLayoutType::getValueAttr() const { return getAttr(); }

/// Verify ComposedLayoutType storage invariants: no error sentinel,
/// positive static shape leaves, addable offset, and a sum that's
/// composable into the inner layout (scalar for swizzle, scalar or
/// weakly congruent for affine).
mlir::LogicalResult ComposedLayoutType::verify(
    llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
    ComposedLayoutAttr attr) {
  auto const &composed = attr.getRef();
  if (cutegen::has_error(composed)) {
    return emitError() << "expects no error(`x`) in layout, but got \""
                       << cutegen::to_string(composed) << "\"";
  }
  // Reject trivial wraps (S<0,0,0> o 0 o B) that are
  // structurally equivalent to the plain outer layout B. The
  // canonical form for such values is !cute.layout, not
  // !cute.composed_layout. composed_layout_t::is_normal_layout()
  // is precisely offset==0 && A is swizzle && swizzle.num_bits()==0.
  if (composed.is_normal_layout()) {
    return emitError()
           << "expects a non-trivial composed layout (with swizzle bits "
              "or non-zero offset); use `!cute.layout` for trivial "
              "wraps, but got \""
           << cutegen::to_string(composed) << "\"";
  }

  auto hasNonPositiveShape = [](cutegen::layout const &lyt) {
    return cutegen::any_leaf_is(lyt.shape(), [](auto const &e) {
      return cutegen::holds_int(e) && cutegen::get_int(e) <= 0;
    });
  };
  if (hasNonPositiveShape(composed.layout_b()) ||
      (composed.is_a_affine() && hasNonPositiveShape(composed.layout_a()))) {
    return emitError() << "expects positive shape mode, but got \""
                       << cutegen::to_string(composed) << "\"";
  }

  // Stride invariants on the embedded layouts (mirroring LayoutType).
  // Run before the addable / composability checks so a malformed
  // stride is reported with the dedicated diagnostic rather than as a
  // downstream composability failure. Outer is always a layout; inner
  // is a layout only when affine.
  auto outerStrideResult =
      verifyStrideInvariants(emitError, composed.layout_b().stride());
  if (mlir::failed(outerStrideResult)) {
    return outerStrideResult;
  }
  if (composed.is_a_affine()) {
    auto innerStrideResult =
        verifyStrideInvariants(emitError, composed.layout_a().stride());
    if (mlir::failed(innerStrideResult)) {
      return innerStrideResult;
    }
  }

  // Addable: the offset and layout_eval(0, outer) must be compatible
  // under arith-tuple addition (no scaled-basis-vs-integer mismatch
  // or rank disagreement).
  auto offset_b = cutegen::layout_eval(0, composed.layout_b());
  auto sum =
      cutegen::arith_tuple_sum<decltype(offset_b)>(composed.offset(), offset_b);
  if (cutegen::has_error(sum)) {
    return emitError() << "expects offset and `layout_eval(0, outer)` to be "
                          "addable, but got "
                       << cutegen::to_string(composed.offset()) << " and "
                       << cutegen::to_string(offset_b);
  }

  // Swizzle inner: the arith-tuple sum must be a scalar (int or
  // dynamic int) — swizzles can only consume scalar indices, so any
  // scaled-basis structure surviving from the offset or outer is a
  // composability error.
  if (composed.is_a_swizzle() && !cutegen::holds_int_or_dynamic_int(sum)) {
    return emitError() << "swizzle layout expects scalar `offset` and "
                          "`outer` without scaled basis, but got "
                       << cutegen::to_string(composed.offset()) << " and "
                       << cutegen::to_string(composed.layout_b());
  }

  // Affine inner: the sum either is a scalar (and layout_a indexes
  // it directly) or matches layout_a's shape profile so each leaf
  // dispatches to the corresponding mode of A.
  if (composed.is_a_affine() && !cutegen::holds_int_or_dynamic_int(sum) &&
      !cutegen::weakly_congruent(sum, composed.layout_a().shape())) {
    return emitError()
           << "expects arith sum of `layout_eval(0, outer)` and `offset` to be "
              "scalar or weakly congruent to inner shape, but got sum "
           << cutegen::to_string(sum) << " and inner shape "
           << cutegen::to_string(composed.layout_a().shape());
  }

  return mlir::success();
}

llvm::TypeSize
ComposedLayoutType::getTypeSize(const mlir::DataLayout &dataLayout,
                                mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSize(cg::get_llvm_type(builder, getRef()));
}

llvm::TypeSize ComposedLayoutType::getTypeSizeInBits(
    const mlir::DataLayout &dataLayout,
    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeSizeInBits(cg::get_llvm_type(builder, getRef()));
}

uint64_t
ComposedLayoutType::getABIAlignment(const mlir::DataLayout &dataLayout,
                                    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeABIAlignment(cg::get_llvm_type(builder, getRef()));
}

uint64_t ComposedLayoutType::getPreferredAlignment(
    const mlir::DataLayout &dataLayout,
    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypePreferredAlignment(
      cg::get_llvm_type(builder, getRef()));
}

std::optional<uint64_t> ComposedLayoutType::getIndexBitwidth(
    const mlir::DataLayout &dataLayout,
    mlir::DataLayoutEntryListRef params) const {
  OpBuilder builder(getContext());
  return dataLayout.getTypeIndexBitwidth(cg::get_llvm_type(builder, getRef()));
}

bool ComposedLayoutType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
ComposedLayoutType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                                  mlir::Location loc) const {
  OpBuilder builder(getContext());
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          cg::get_llvm_type(builder, getRef()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}

//===----------------------------------------------------------------------===//
// SwizzleType — custom assembly format
//===----------------------------------------------------------------------===//

mlir::Type SwizzleType::parse(mlir::AsmParser &parser) {
  auto loc = parser.getCurrentLocation();
  if (parser.parseLess()) {
    return {};
  }
  std::string str;
  if (parser.parseString(&str)) {
    return {};
  }
  auto opt = cutegen::from_string<cutegen::swizzle>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse swizzle from \"" + str + "\"");
    return {};
  }
  if (parser.parseGreater()) {
    return {};
  }
  auto attr = SwizzleAttr::get(parser.getContext(), std::move(*opt));
  return SwizzleType::getChecked([&] { return parser.emitError(loc); },
                                 parser.getContext(), attr);
}

void SwizzleType::print(mlir::AsmPrinter &printer) const {
  printer << '<';
  printer.printString(cutegen::to_string(getRef()));
  printer << '>';
}

bool SwizzleType::isStatic() const { return true; }

mlir::Attribute SwizzleType::getValueAttr() const { return getAttr(); }

/// Verify SwizzleType storage invariants. Defense-in-depth — the
/// string parser already rejects invalid swizzle parameters via
/// cutegen::from_string<cutegen::swizzle>, but programmatic
/// construction goes around the parser, so re-check here.
///
/// cutegen::swizzle::is_valid (swizzle.hpp) enforces two
/// invariants on S<num_bits, num_base, num_shift>:
///   1. |num_shift| + num_bits + num_base <= 32 — parameters
///      must fit within the swizzle's 32-bit working width.
///   2. |num_shift| >= num_bits — the shift amount must cover
///      the mask width so the Y and Z masks do not overlap.
mlir::LogicalResult
SwizzleType::verify(llvm::function_ref<mlir::InFlightDiagnostic()> emitError,
                    SwizzleAttr attr) {
  auto const &sw = attr.getRef();
  uint32_t numBits = sw.num_bits();
  uint32_t numBase = sw.num_base();
  int32_t numShift = sw.num_shift();
  uint32_t absShift = static_cast<uint32_t>(std::abs(numShift));
  constexpr uint32_t kBitWidth = 32;

  if (absShift + numBits + numBase > kBitWidth) {
    return emitError() << "expects |num_shift| + num_bits + num_base <= "
                       << kBitWidth << ", but got " << absShift << " + "
                       << numBits << " + " << numBase << " = "
                       << (absShift + numBits + numBase) << " for swizzle "
                       << cutegen::to_string(sw);
  }
  if (absShift < numBits) {
    return emitError() << "expects |num_shift| >= num_bits, but got "
                       << absShift << " < " << numBits << " for swizzle "
                       << cutegen::to_string(sw);
  }
  return mlir::success();
}

// A swizzle is a compile-time-only object whose runtime representation is an
// empty LLVM struct (mirroring convertSwizzleType in CuteTypeConverter.cpp), so
// the data-layout queries delegate to that struct rather than to
// cg::get_llvm_type.
static mlir::Type getSwizzleLLVMType(mlir::MLIRContext *ctx) {
  return LLVM::LLVMStructType::getLiteral(ctx, SmallVector<mlir::Type>{});
}

llvm::TypeSize
SwizzleType::getTypeSize(const mlir::DataLayout &dataLayout,
                         mlir::DataLayoutEntryListRef params) const {
  return dataLayout.getTypeSize(getSwizzleLLVMType(getContext()));
}

llvm::TypeSize
SwizzleType::getTypeSizeInBits(const mlir::DataLayout &dataLayout,
                               mlir::DataLayoutEntryListRef params) const {
  return dataLayout.getTypeSizeInBits(getSwizzleLLVMType(getContext()));
}

uint64_t
SwizzleType::getABIAlignment(const mlir::DataLayout &dataLayout,
                             mlir::DataLayoutEntryListRef params) const {
  return dataLayout.getTypeABIAlignment(getSwizzleLLVMType(getContext()));
}

uint64_t
SwizzleType::getPreferredAlignment(const mlir::DataLayout &dataLayout,
                                   mlir::DataLayoutEntryListRef params) const {
  return dataLayout.getTypePreferredAlignment(getSwizzleLLVMType(getContext()));
}

std::optional<uint64_t>
SwizzleType::getIndexBitwidth(const mlir::DataLayout &dataLayout,
                              mlir::DataLayoutEntryListRef params) const {
  return dataLayout.getTypeIndexBitwidth(getSwizzleLLVMType(getContext()));
}

bool SwizzleType::areCompatible(
    mlir::DataLayoutEntryListRef oldLayout,
    mlir::DataLayoutEntryListRef newLayout,
    mlir::DataLayoutSpecInterface newSpec,
    const mlir::DataLayoutIdentifiedEntryMap &identified) const {
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          getSwizzleLLVMType(getContext()))) {
    return dlTy.areCompatible(oldLayout, newLayout, newSpec, identified);
  }
  return true;
}

llvm::LogicalResult
SwizzleType::verifyEntries(mlir::DataLayoutEntryListRef entries,
                           mlir::Location loc) const {
  if (auto dlTy = llvm::dyn_cast<mlir::DataLayoutTypeInterface>(
          getSwizzleLLVMType(getContext()))) {
    return dlTy.verifyEntries(entries, loc);
  }
  return mlir::success();
}
