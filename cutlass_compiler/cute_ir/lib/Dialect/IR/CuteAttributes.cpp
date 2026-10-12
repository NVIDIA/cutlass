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

#include "mlir/IR/DialectImplementation.h"

#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;

//===----------------------------------------------------------------------===//
// CutegenAttrStorage — generic MLIR attribute storage for cutegen objects
//

// Stores a cutegen object (int_tuple, coord, ...) in the MLIR context
// allocator.
//===----------------------------------------------------------------------===//

namespace mlir::cutlass_compiler::cute::detail {

template <class TStorage, class TObject>
struct CutegenAttrStorage : public AttributeStorage {
  using KeyTy = TObject;

  explicit CutegenAttrStorage(TObject t) : obj_(std::move(t)) {}

  bool operator==(const KeyTy &key) const { return key == obj_; }

  static llvm::hash_code hashKey(const KeyTy &key) {
    std::vector<char> buf;
    cutegen::encode(buf, key);
    return llvm::hash_combine_range(buf.begin(), buf.end());
  }

  static TStorage *construct(AttributeStorageAllocator &alloc, KeyTy key) {
    return new (alloc.allocate<TStorage>()) TStorage(std::move(key));
  }

  TObject obj_;
};

struct IntTupleAttrStorage
    : CutegenAttrStorage<IntTupleAttrStorage, cutegen::int_tuple> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct CoordAttrStorage : CutegenAttrStorage<CoordAttrStorage, cutegen::coord> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct ShapeAttrStorage : CutegenAttrStorage<ShapeAttrStorage, cutegen::shape> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct StrideAttrStorage
    : CutegenAttrStorage<StrideAttrStorage, cutegen::stride> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct LayoutAttrStorage
    : CutegenAttrStorage<LayoutAttrStorage, cutegen::layout> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct TileAttrStorage : CutegenAttrStorage<TileAttrStorage, cutegen::tile> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct ComposedLayoutAttrStorage
    : CutegenAttrStorage<ComposedLayoutAttrStorage, cutegen::composed_layout> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

struct SwizzleAttrStorage
    : CutegenAttrStorage<SwizzleAttrStorage, cutegen::swizzle> {
  using CutegenAttrStorage::CutegenAttrStorage;
};

} // namespace mlir::cutlass_compiler::cute::detail

//===----------------------------------------------------------------------===//
// Parse / print helpers
//

// Both helpers share a single < "string" > grammar: the quoted string is the
// cutegen to_string / from_string serialization of the object.
//===----------------------------------------------------------------------===//

namespace {

template <typename T>
std::optional<T> parseCutegenAttr(AsmParser &parser, llvm::StringRef name) {
  if (parser.parseLess()) {
    return std::nullopt;
  }
  std::string str;
  if (parser.parseString(&str)) {
    // parseString already emits "expected string" — no second error needed.
    return std::nullopt;
  }
  auto opt = cutegen::from_string<T>(str);
  if (!opt) {
    parser.emitError(parser.getCurrentLocation(),
                     "failed to parse " + name.str() + " from \"" + str + "\"");
    return std::nullopt;
  }
  if (parser.parseGreater()) {
    return std::nullopt;
  }
  return opt;
}

template <typename T>
void printCutegenAttr(AsmPrinter &printer, const T &value) {
  printer << '<';
  printer.printString(cutegen::to_string(value));
  printer << '>';
}

} // namespace

// Include tablegen-generated attribute class bodies.  Must come after the
// storage class definitions above so IntTupleAttrStorage is complete.
#define GET_ATTRDEF_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteAttrs.cpp.inc"

//===----------------------------------------------------------------------===//
// CuteDialect — attribute registration
//===----------------------------------------------------------------------===//

void CuteDialect::registerCuteAttributes(CuteDialect *dialect) {
  (void)&generatedAttributeParser;
  (void)&generatedAttributePrinter;
  dialect->addAttributes<
#define GET_ATTRDEF_LIST
#include "cute_ir/Dialect/Cute/IR/CuteAttrs.cpp.inc"
      >();
}

//===----------------------------------------------------------------------===//
// IntTupleAttr
//===----------------------------------------------------------------------===//

cutegen::int_tuple const &IntTupleAttr::getRef() const {
  return getImpl()->obj_;
}

Attribute IntTupleAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::int_tuple>(parser, "int_tuple");
  if (!opt) {
    return {};
  }
  return IntTupleAttr::get(parser.getContext(), std::move(*opt));
}

void IntTupleAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// CoordAttr
//===----------------------------------------------------------------------===//

cutegen::coord const &CoordAttr::getRef() const { return getImpl()->obj_; }

Attribute CoordAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::coord>(parser, "coord");
  if (!opt) {
    return {};
  }
  return CoordAttr::get(parser.getContext(), std::move(*opt));
}

void CoordAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// ShapeAttr
//===----------------------------------------------------------------------===//

cutegen::shape const &ShapeAttr::getRef() const { return getImpl()->obj_; }

Attribute ShapeAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::shape>(parser, "shape");
  if (!opt) {
    return {};
  }
  return ShapeAttr::get(parser.getContext(), std::move(*opt));
}

void ShapeAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// StrideAttr
//===----------------------------------------------------------------------===//

cutegen::stride const &StrideAttr::getRef() const { return getImpl()->obj_; }

Attribute StrideAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::stride>(parser, "stride");
  if (!opt) {
    return {};
  }
  return StrideAttr::get(parser.getContext(), std::move(*opt));
}

void StrideAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// LayoutAttr
//===----------------------------------------------------------------------===//

cutegen::layout const &LayoutAttr::getRef() const { return getImpl()->obj_; }

Attribute LayoutAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::layout>(parser, "layout");
  if (!opt) {
    return {};
  }
  return LayoutAttr::get(parser.getContext(), std::move(*opt));
}

void LayoutAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// TileAttr
//===----------------------------------------------------------------------===//

cutegen::tile const &TileAttr::getRef() const { return getImpl()->obj_; }

Attribute TileAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::tile>(parser, "tile");
  if (!opt) {
    return {};
  }
  return TileAttr::get(parser.getContext(), std::move(*opt));
}

void TileAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// ComposedLayoutAttr
//===----------------------------------------------------------------------===//

cutegen::composed_layout const &ComposedLayoutAttr::getRef() const {
  return getImpl()->obj_;
}

Attribute ComposedLayoutAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt =
      parseCutegenAttr<cutegen::composed_layout>(parser, "composed_layout");
  if (!opt) {
    return {};
  }
  return ComposedLayoutAttr::get(parser.getContext(), std::move(*opt));
}

void ComposedLayoutAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}

//===----------------------------------------------------------------------===//
// SwizzleAttr
//===----------------------------------------------------------------------===//

cutegen::swizzle const &SwizzleAttr::getRef() const { return getImpl()->obj_; }

Attribute SwizzleAttr::parse(AsmParser &parser, Type /*type*/) {
  auto opt = parseCutegenAttr<cutegen::swizzle>(parser, "swizzle");
  if (!opt) {
    return {};
  }
  return SwizzleAttr::get(parser.getContext(), std::move(*opt));
}

void SwizzleAttr::print(AsmPrinter &printer) const {
  printCutegenAttr(printer, getRef());
}
