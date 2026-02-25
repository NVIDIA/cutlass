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
    cf.br ^bb1(%c0 : index)
  ^bb1(%35: index):  // 2 preds: ^bb0, ^bb29
    %36 = arith.cmpi slt, %35, %28 : index
    cf.cond_br %36, ^bb2, ^bb30
  ^bb2:  // pred: ^bb1
    %37 = arith.cmpi ne, %35, %31 : index
    %38 = arith.cmpi ne, %35, %c0 : index
    cf.cond_br %38, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    %39 = llvm.getelementptr %12[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %40 = llvm.call @printf(%39) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %41 = llvm.call @printf(%32) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb5(%c0 : index)
  ^bb5(%42: index):  // 2 preds: ^bb4, ^bb26
    %43 = arith.cmpi slt, %42, %26 : index
    cf.cond_br %43, ^bb6, ^bb27
  ^bb6:  // pred: ^bb5
    %44 = arith.cmpi sgt, %42, %c2 : index
    %45 = arith.cmpi slt, %42, %33 : index
    %46 = arith.andi %44, %45 : i1
    cf.cond_br %46, ^bb7, ^bb10
  ^bb7:  // pred: ^bb6
    %47 = arith.cmpi eq, %42, %c3 : index
    cf.cond_br %47, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %48 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
    %49 = llvm.call @printf(%48) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb9
  ^bb9:  // 2 preds: ^bb7, ^bb8
    cf.br ^bb26
  ^bb10:  // pred: ^bb6
    %50 = arith.cmpi ne, %42, %c0 : index
    %51 = arith.subi %26, %c1 : index
    %52 = arith.cmpi slt, %42, %51 : index
    cf.cond_br %50, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    %53 = llvm.getelementptr %9[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<9 x i8>
    %54 = llvm.call @printf(%53) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %55 = llvm.getelementptr %8[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %56 = llvm.call @printf(%55) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %57 = arith.subi %27, %c3 : index
    cf.br ^bb13(%c0 : index)
  ^bb13(%58: index):  // 2 preds: ^bb12, ^bb22
    %59 = arith.cmpi slt, %58, %27 : index
    cf.cond_br %59, ^bb14, ^bb23
  ^bb14:  // pred: ^bb13
    %60 = arith.cmpi sgt, %58, %c2 : index
    %61 = arith.cmpi slt, %58, %57 : index
    %62 = arith.andi %60, %61 : i1
    cf.cond_br %62, ^bb15, ^bb18
  ^bb15:  // pred: ^bb14
    %63 = arith.cmpi eq, %58, %c3 : index
    cf.cond_br %63, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %64 = llvm.getelementptr %7[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %65 = llvm.call @printf(%64) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    cf.br ^bb22
  ^bb18:  // pred: ^bb14
    %66 = arith.index_cast %35 : index to i32
    %67 = arith.index_cast %58 : index to i32
    %68 = arith.index_cast %42 : index to i32
    %coord = cute.make_coord(%68, %67, %66) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
    %69 = cute.memref.load(%view, %coord) : (!memref_generic_f32_1, !cute.coord<"(?,?,?)">) -> f32
    %70 = arith.cmpf oge, %69, %cst : f32
    cf.cond_br %70, ^bb19, ^bb20
  ^bb19:  // pred: ^bb18
    %71 = arith.extf %69 : f32 to f64
    %72 = llvm.getelementptr %6[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %73 = llvm.call @printf(%72, %71) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    cf.br ^bb21
  ^bb20:  // pred: ^bb18
    %74 = arith.extf %69 : f32 to f64
    %75 = llvm.getelementptr %5[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<5 x i8>
    %76 = llvm.call @printf(%75, %74) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    cf.br ^bb21
  ^bb21:  // 2 preds: ^bb19, ^bb20
    cf.br ^bb22
  ^bb22:  // 2 preds: ^bb17, ^bb21
    %77 = arith.addi %58, %c1 : index
    cf.br ^bb13(%77 : index)
  ^bb23:  // pred: ^bb13
    %78 = llvm.getelementptr %4[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %79 = llvm.call @printf(%78) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.cond_br %52, ^bb24, ^bb25
  ^bb24:  // pred: ^bb23
    %80 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %81 = llvm.call @printf(%80) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb25
  ^bb25:  // 2 preds: ^bb23, ^bb24
    cf.br ^bb26
  ^bb26:  // 2 preds: ^bb9, ^bb25
    %82 = arith.addi %42, %c1 : index
    cf.br ^bb5(%82 : index)
  ^bb27:  // pred: ^bb5
    %83 = llvm.call @printf(%34) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.cond_br %37, ^bb28, ^bb29
  ^bb28:  // pred: ^bb27
    %84 = llvm.getelementptr %1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
    %85 = llvm.call @printf(%84) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    cf.br ^bb29
  ^bb29:  // 2 preds: ^bb27, ^bb28
    %86 = arith.addi %35, %c1 : index
    cf.br ^bb1(%86 : index)
  ^bb30:  // pred: ^bb1
    %87 = llvm.getelementptr %0[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %88 = llvm.call @printf(%87) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    return
  }
}
