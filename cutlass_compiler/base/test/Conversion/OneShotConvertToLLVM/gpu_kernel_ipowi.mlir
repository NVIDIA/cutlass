// RUN: base-opt -one-shot-convert-to-llvm %s | FileCheck %s

// The native conversion must lower integer power before GPU LLVM/NVVM lowering.
// The outlined helper is localized into the GPU module because GPU symbols use
// a separate symbol table from host functions.

// CHECK-LABEL: gpu.module @kernels
// CHECK-LABEL: llvm.func @i32_kernel
// CHECK-NOT: math.ipowi
// CHECK-NOT: math.
// CHECK: llvm.call @kernels___mlir_math_ipowi_i32
// CHECK: llvm.return
// CHECK-LABEL: llvm.func @i64_kernel
// CHECK-NOT: math.ipowi
// CHECK-NOT: math.
// CHECK: llvm.call @kernels___mlir_math_ipowi_i64
// CHECK: llvm.return
// CHECK-LABEL: llvm.func @vector_kernel
// CHECK-NOT: math.ipowi
// CHECK-NOT: math.
// CHECK: llvm.call @kernels___mlir_math_ipowi_i32
// CHECK: llvm.return
// CHECK-LABEL: llvm.func linkonce_odr @kernels___mlir_math_ipowi_i32
// CHECK: llvm.icmp
// CHECK: llvm.mul
// CHECK: llvm.lshr
// CHECK: llvm.return
// CHECK-LABEL: llvm.func linkonce_odr @kernels___mlir_math_ipowi_i64
// CHECK: llvm.icmp
// CHECK: llvm.mul
// CHECK: llvm.lshr
// CHECK: llvm.return

gpu.module @kernels {
  gpu.func @i32_kernel(%base: i32, %exponent: i32) kernel {
    %result = math.ipowi %base, %exponent : i32
    gpu.return
  }
  gpu.func @i64_kernel(%base: i64, %exponent: i64) kernel {
    %result = math.ipowi %base, %exponent : i64
    gpu.return
  }
  gpu.func @vector_kernel(%base: vector<2xi32>, %exponent: vector<2xi32>) kernel {
    %result = math.ipowi %base, %exponent : vector<2xi32>
    gpu.return
  }
}
