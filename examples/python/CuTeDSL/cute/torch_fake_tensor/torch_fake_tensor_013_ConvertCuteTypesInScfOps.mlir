!memref_generic_f32_ = !cute.memref<f32, generic, "(3,4):(4,1)">
!memref_generic_f32_1 = !cute.memref<f32, generic, "(3,4,(1)):(4,1,(0))">
module attributes {gpu.container_module} {
  llvm.mlir.global internal constant @printfFormat_14(")\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_13(",\0A\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_12("]\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_11(",\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_10("]\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_9("%f, \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_8(" %f, \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_7("..., \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_6("[\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_5("        \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_4("        ...\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_3("[\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_2("       \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_1("       \00") {addr_space = 0 : i32}
  llvm.func @printf(!llvm.ptr, ...) -> i32
  llvm.mlir.global internal constant @printfFormat_0("tensor(raw_ptr(0x%016llx: f32, generic, align<4>) o (3,4):(4,1), data=\0A\00") {addr_space = 0 : i32}
  gpu.module @kernels {
  }
  func.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !memref_generic_f32_) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.addressof @printfFormat_14 : !llvm.ptr
    %1 = llvm.mlir.addressof @printfFormat_13 : !llvm.ptr
    %2 = llvm.mlir.addressof @printfFormat_12 : !llvm.ptr
    %3 = llvm.mlir.addressof @printfFormat_11 : !llvm.ptr
    %4 = llvm.mlir.addressof @printfFormat_10 : !llvm.ptr
    %5 = llvm.mlir.addressof @printfFormat_9 : !llvm.ptr
    %6 = llvm.mlir.addressof @printfFormat_8 : !llvm.ptr
    %cst = arith.constant 0.000000e+00 : f32
    %7 = llvm.mlir.addressof @printfFormat_7 : !llvm.ptr
    %8 = llvm.mlir.addressof @printfFormat_6 : !llvm.ptr
    %9 = llvm.mlir.addressof @printfFormat_5 : !llvm.ptr
    %10 = llvm.mlir.addressof @printfFormat_4 : !llvm.ptr
    %c3 = arith.constant 3 : index
    %c2 = arith.constant 2 : index
    %11 = llvm.mlir.addressof @printfFormat_3 : !llvm.ptr
    %12 = llvm.mlir.addressof @printfFormat_2 : !llvm.ptr
    %13 = llvm.mlir.addressof @printfFormat_1 : !llvm.ptr
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %14 = cute.static : !cute.int_tuple<"1">
    %15 = cute.static : !cute.int_tuple<"4">
    %16 = cute.static : !cute.int_tuple<"3">
    %17 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %18 = cute.static : !cute.layout<"(3,4,(1)):(4,1,(0))">
    %iter = cute.get_iter(%arg0) : !memref_generic_f32_
    %view = cute.make_view(%iter, %18) : !memref_generic_f32_1
    %19 = builtin.unrealized_conversion_cast %iter : !cute.ptr<f32, generic> to !llvm.ptr
    %20 = llvm.ptrtoint %19 : !llvm.ptr to i64
    %21 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<72 x i8>
    %22 = llvm.call @printf(%21, %20) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %23 = cute.get_scalars(%16) : !cute.int_tuple<"3">
    %24 = cute.get_scalars(%15) : !cute.int_tuple<"4">
    %25 = cute.get_scalars(%14) : !cute.int_tuple<"1">
    %26 = arith.index_cast %23 : i32 to index
    %27 = arith.index_cast %24 : i32 to index
    %28 = arith.index_cast %25 : i32 to index
    %29 = llvm.getelementptr %13[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %30 = llvm.call @printf(%29) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %31 = arith.subi %28, %c1 : index
    %32 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %33 = arith.subi %26, %c3 : index
    %34 = llvm.getelementptr %2[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    scf.for %arg1 = %c0 to %28 step %c1 {
      %37 = arith.cmpi ne, %arg1, %31 : index
      %38 = arith.cmpi ne, %arg1, %c0 : index
      scf.if %38 {
        %41 = llvm.getelementptr %12[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
        %42 = llvm.call @printf(%41) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
      %39 = llvm.call @printf(%32) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      scf.for %arg2 = %c0 to %26 step %c1 {
        %41 = arith.cmpi sgt, %arg2, %c2 : index
        %42 = arith.cmpi slt, %arg2, %33 : index
        %43 = arith.andi %41, %42 : i1
        scf.if %43 {
          %44 = arith.cmpi eq, %arg2, %c3 : index
          scf.if %44 {
            %45 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
            %46 = llvm.call @printf(%45) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        } else {
          %44 = arith.cmpi ne, %arg2, %c0 : index
          %45 = arith.subi %26, %c1 : index
          %46 = arith.cmpi slt, %arg2, %45 : index
          scf.if %44 {
            %52 = llvm.getelementptr %9[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<9 x i8>
            %53 = llvm.call @printf(%52) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
          %47 = llvm.getelementptr %8[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
          %48 = llvm.call @printf(%47) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          %49 = arith.subi %27, %c3 : index
          scf.for %arg3 = %c0 to %27 step %c1 {
            %52 = arith.cmpi sgt, %arg3, %c2 : index
            %53 = arith.cmpi slt, %arg3, %49 : index
            %54 = arith.andi %52, %53 : i1
            scf.if %54 {
              %55 = arith.cmpi eq, %arg3, %c3 : index
              scf.if %55 {
                %56 = llvm.getelementptr %7[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
                %57 = llvm.call @printf(%56) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
              }
            } else {
              %55 = arith.index_cast %arg1 : index to i32
              %56 = arith.index_cast %arg3 : index to i32
              %57 = arith.index_cast %arg2 : index to i32
              %coord = cute.make_coord(%57, %56, %55) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
              %58 = cute.memref.load(%view, %coord) : (!memref_generic_f32_1, !cute.coord<"(?,?,?)">) -> f32
              %59 = arith.cmpf oge, %58, %cst : f32
              scf.if %59 {
                %60 = arith.extf %58 : f32 to f64
                %61 = llvm.getelementptr %6[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
                %62 = llvm.call @printf(%61, %60) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              } else {
                %60 = arith.extf %58 : f32 to f64
                %61 = llvm.getelementptr %5[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<5 x i8>
                %62 = llvm.call @printf(%61, %60) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              }
            }
          }
          %50 = llvm.getelementptr %4[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
          %51 = llvm.call @printf(%50) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          scf.if %46 {
            %52 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
            %53 = llvm.call @printf(%52) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        }
      }
      %40 = llvm.call @printf(%34) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      scf.if %37 {
        %41 = llvm.getelementptr %1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
        %42 = llvm.call @printf(%41) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
    }
    %35 = llvm.getelementptr %0[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %36 = llvm.call @printf(%35) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    return
  }
}
