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
    %iter = cute.get_iter(%arg0) : !memref_generic_f32_
    %0 = cute.static : !cute.layout<"(3,4,(1)):(4,1,(0))">
    %view = cute.make_view(%iter, %0) : !memref_generic_f32_1
    %1 = builtin.unrealized_conversion_cast %iter : !cute.ptr<f32, generic> to !llvm.ptr
    %2 = llvm.ptrtoint %1 : !llvm.ptr to i64
    %3 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %c0_i64 = arith.constant 0 : i64
    %4 = llvm.getelementptr %3[%c0_i64, %c0_i64] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<72 x i8>
    %5 = llvm.call @printf(%4, %2) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %6 = cute.static : !cute.int_tuple<"3">
    %7 = cute.static : !cute.int_tuple<"4">
    %8 = cute.static : !cute.int_tuple<"1">
    %9 = cute.get_scalars(%6) : !cute.int_tuple<"3">
    %10 = cute.get_scalars(%7) : !cute.int_tuple<"4">
    %11 = cute.get_scalars(%8) : !cute.int_tuple<"1">
    %12 = arith.index_cast %9 : i32 to index
    %13 = arith.index_cast %10 : i32 to index
    %14 = arith.index_cast %11 : i32 to index
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %15 = llvm.mlir.addressof @printfFormat_1 : !llvm.ptr
    %c0_i64_0 = arith.constant 0 : i64
    %16 = llvm.getelementptr %15[%c0_i64_0, %c0_i64_0] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<8 x i8>
    %17 = llvm.call @printf(%16) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    scf.for %arg1 = %c0 to %14 step %c1 {
      %21 = arith.subi %14, %c1 : index
      %22 = arith.cmpi ne, %arg1, %21 : index
      %23 = arith.cmpi ne, %arg1, %c0 : index
      scf.if %23 {
        %30 = llvm.mlir.addressof @printfFormat_2 : !llvm.ptr
        %c0_i64_5 = arith.constant 0 : i64
        %31 = llvm.getelementptr %30[%c0_i64_5, %c0_i64_5] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<8 x i8>
        %32 = llvm.call @printf(%31) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
      %24 = llvm.mlir.addressof @printfFormat_3 : !llvm.ptr
      %c0_i64_2 = arith.constant 0 : i64
      %25 = llvm.getelementptr %24[%c0_i64_2, %c0_i64_2] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
      %26 = llvm.call @printf(%25) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      %c1_3 = arith.constant 1 : index
      scf.for %arg2 = %c0 to %12 step %c1_3 {
        %c2 = arith.constant 2 : index
        %c3 = arith.constant 3 : index
        %30 = arith.cmpi sgt, %arg2, %c2 : index
        %31 = arith.subi %12, %c3 : index
        %32 = arith.cmpi slt, %arg2, %31 : index
        %33 = arith.andi %30, %32 : i1
        scf.if %33 {
          %c3_5 = arith.constant 3 : index
          %34 = arith.cmpi eq, %arg2, %c3_5 : index
          scf.if %34 {
            %35 = llvm.mlir.addressof @printfFormat_4 : !llvm.ptr
            %c0_i64_6 = arith.constant 0 : i64
            %36 = llvm.getelementptr %35[%c0_i64_6, %c0_i64_6] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<13 x i8>
            %37 = llvm.call @printf(%36) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        } else {
          %34 = arith.cmpi ne, %arg2, %c0 : index
          %35 = arith.subi %12, %c1 : index
          %36 = arith.cmpi slt, %arg2, %35 : index
          scf.if %34 {
            %43 = llvm.mlir.addressof @printfFormat_5 : !llvm.ptr
            %c0_i64_9 = arith.constant 0 : i64
            %44 = llvm.getelementptr %43[%c0_i64_9, %c0_i64_9] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<9 x i8>
            %45 = llvm.call @printf(%44) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
          %37 = llvm.mlir.addressof @printfFormat_6 : !llvm.ptr
          %c0_i64_5 = arith.constant 0 : i64
          %38 = llvm.getelementptr %37[%c0_i64_5, %c0_i64_5] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
          %39 = llvm.call @printf(%38) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          %c0_6 = arith.constant 0 : index
          %c1_7 = arith.constant 1 : index
          scf.for %arg3 = %c0_6 to %13 step %c1_7 {
            %c2_9 = arith.constant 2 : index
            %c3_10 = arith.constant 3 : index
            %43 = arith.cmpi sgt, %arg3, %c2_9 : index
            %44 = arith.subi %13, %c3_10 : index
            %45 = arith.cmpi slt, %arg3, %44 : index
            %46 = arith.andi %43, %45 : i1
            scf.if %46 {
              %c3_11 = arith.constant 3 : index
              %47 = arith.cmpi eq, %arg3, %c3_11 : index
              scf.if %47 {
                %48 = llvm.mlir.addressof @printfFormat_7 : !llvm.ptr
                %c0_i64_12 = arith.constant 0 : i64
                %49 = llvm.getelementptr %48[%c0_i64_12, %c0_i64_12] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<6 x i8>
                %50 = llvm.call @printf(%49) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
              }
            } else {
              %47 = arith.index_cast %arg1 : index to i32
              %48 = arith.index_cast %arg3 : index to i32
              %49 = arith.index_cast %arg2 : index to i32
              %coord = cute.make_coord(%49, %48, %47) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
              %50 = cute.memref.load(%view, %coord) : (!memref_generic_f32_1, !cute.coord<"(?,?,?)">) -> f32
              %cst = arith.constant 0.000000e+00 : f32
              %51 = arith.cmpf oge, %50, %cst : f32
              scf.if %51 {
                %52 = arith.extf %50 : f32 to f64
                %53 = llvm.mlir.addressof @printfFormat_8 : !llvm.ptr
                %c0_i64_11 = arith.constant 0 : i64
                %54 = llvm.getelementptr %53[%c0_i64_11, %c0_i64_11] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<6 x i8>
                %55 = llvm.call @printf(%54, %52) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              } else {
                %52 = arith.extf %50 : f32 to f64
                %53 = llvm.mlir.addressof @printfFormat_9 : !llvm.ptr
                %c0_i64_11 = arith.constant 0 : i64
                %54 = llvm.getelementptr %53[%c0_i64_11, %c0_i64_11] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<5 x i8>
                %55 = llvm.call @printf(%54, %52) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              }
            }
          }
          %40 = llvm.mlir.addressof @printfFormat_10 : !llvm.ptr
          %c0_i64_8 = arith.constant 0 : i64
          %41 = llvm.getelementptr %40[%c0_i64_8, %c0_i64_8] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
          %42 = llvm.call @printf(%41) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          scf.if %36 {
            %43 = llvm.mlir.addressof @printfFormat_11 : !llvm.ptr
            %c0_i64_9 = arith.constant 0 : i64
            %44 = llvm.getelementptr %43[%c0_i64_9, %c0_i64_9] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<3 x i8>
            %45 = llvm.call @printf(%44) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        }
      }
      %27 = llvm.mlir.addressof @printfFormat_12 : !llvm.ptr
      %c0_i64_4 = arith.constant 0 : i64
      %28 = llvm.getelementptr %27[%c0_i64_4, %c0_i64_4] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
      %29 = llvm.call @printf(%28) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      scf.if %22 {
        %30 = llvm.mlir.addressof @printfFormat_13 : !llvm.ptr
        %c0_i64_5 = arith.constant 0 : i64
        %31 = llvm.getelementptr %30[%c0_i64_5, %c0_i64_5] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<4 x i8>
        %32 = llvm.call @printf(%31) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
    }
    %18 = llvm.mlir.addressof @printfFormat_14 : !llvm.ptr
    %c0_i64_1 = arith.constant 0 : i64
    %19 = llvm.getelementptr %18[%c0_i64_1, %c0_i64_1] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<3 x i8>
    %20 = llvm.call @printf(%19) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    return
  }
}
