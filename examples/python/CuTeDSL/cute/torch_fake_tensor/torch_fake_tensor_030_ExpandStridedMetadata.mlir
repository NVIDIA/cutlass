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
  gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_90a">] {
  }
  llvm.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(4 : i32) : i32
    %2 = llvm.mlir.constant(3 : i32) : i32
    %3 = llvm.mlir.addressof @printfFormat_14 : !llvm.ptr
    %4 = llvm.mlir.addressof @printfFormat_13 : !llvm.ptr
    %5 = llvm.mlir.addressof @printfFormat_12 : !llvm.ptr
    %6 = llvm.mlir.addressof @printfFormat_11 : !llvm.ptr
    %7 = llvm.mlir.addressof @printfFormat_10 : !llvm.ptr
    %8 = llvm.mlir.addressof @printfFormat_9 : !llvm.ptr
    %9 = llvm.mlir.addressof @printfFormat_8 : !llvm.ptr
    %10 = llvm.mlir.constant(0.000000e+00 : f32) : f32
    %11 = llvm.mlir.addressof @printfFormat_7 : !llvm.ptr
    %12 = llvm.mlir.addressof @printfFormat_6 : !llvm.ptr
    %13 = llvm.mlir.addressof @printfFormat_5 : !llvm.ptr
    %14 = llvm.mlir.addressof @printfFormat_4 : !llvm.ptr
    %15 = llvm.mlir.constant(3 : index) : i64
    %16 = llvm.mlir.constant(2 : index) : i64
    %17 = llvm.mlir.addressof @printfFormat_3 : !llvm.ptr
    %18 = llvm.mlir.addressof @printfFormat_2 : !llvm.ptr
    %19 = llvm.mlir.addressof @printfFormat_1 : !llvm.ptr
    %20 = llvm.mlir.constant(1 : index) : i64
    %21 = llvm.mlir.constant(0 : index) : i64
    %22 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %23 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %24 = llvm.ptrtoint %23 : !llvm.ptr to i64
    %25 = llvm.getelementptr %22[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<72 x i8>
    %26 = llvm.call @printf(%25, %24) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %27 = llvm.sext %2 : i32 to i64
    %28 = llvm.sext %1 : i32 to i64
    %29 = llvm.sext %0 : i32 to i64
    %30 = llvm.getelementptr %19[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %31 = llvm.call @printf(%30) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %32 = llvm.sub %29, %20 : i64
    %33 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %34 = llvm.sub %27, %15 : i64
    %35 = llvm.getelementptr %5[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    llvm.br ^bb1(%21 : i64)
  ^bb1(%36: i64):  // 2 preds: ^bb0, ^bb27
    %37 = llvm.icmp "slt" %36, %29 : i64
    llvm.cond_br %37, ^bb2, ^bb28
  ^bb2:  // pred: ^bb1
    %38 = llvm.icmp "ne" %36, %32 : i64
    %39 = llvm.icmp "ne" %36, %21 : i64
    llvm.cond_br %39, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    %40 = llvm.getelementptr %18[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %41 = llvm.call @printf(%40) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %42 = llvm.call @printf(%33) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb5(%21 : i64)
  ^bb5(%43: i64):  // 2 preds: ^bb4, ^bb24
    %44 = llvm.icmp "slt" %43, %27 : i64
    llvm.cond_br %44, ^bb6, ^bb25
  ^bb6:  // pred: ^bb5
    %45 = llvm.icmp "sgt" %43, %16 : i64
    %46 = llvm.icmp "slt" %43, %34 : i64
    %47 = llvm.and %45, %46 : i1
    llvm.cond_br %47, ^bb7, ^bb10
  ^bb7:  // pred: ^bb6
    %48 = llvm.icmp "eq" %43, %15 : i64
    llvm.cond_br %48, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %49 = llvm.getelementptr %14[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
    %50 = llvm.call @printf(%49) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb9
  ^bb9:  // 4 preds: ^bb7, ^bb8, ^bb22, ^bb23
    llvm.br ^bb24
  ^bb10:  // pred: ^bb6
    %51 = llvm.icmp "ne" %43, %21 : i64
    %52 = llvm.sub %27, %20 : i64
    %53 = llvm.icmp "slt" %43, %52 : i64
    llvm.cond_br %51, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    %54 = llvm.getelementptr %13[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<9 x i8>
    %55 = llvm.call @printf(%54) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %56 = llvm.getelementptr %12[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %57 = llvm.call @printf(%56) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %58 = llvm.sub %28, %15 : i64
    llvm.br ^bb13(%21 : i64)
  ^bb13(%59: i64):  // 2 preds: ^bb12, ^bb21
    %60 = llvm.icmp "slt" %59, %28 : i64
    llvm.cond_br %60, ^bb14, ^bb22
  ^bb14:  // pred: ^bb13
    %61 = llvm.icmp "sgt" %59, %16 : i64
    %62 = llvm.icmp "slt" %59, %58 : i64
    %63 = llvm.and %61, %62 : i1
    llvm.cond_br %63, ^bb15, ^bb18
  ^bb15:  // pred: ^bb14
    %64 = llvm.icmp "eq" %59, %15 : i64
    llvm.cond_br %64, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %65 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %66 = llvm.call @printf(%65) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb17
  ^bb17:  // 4 preds: ^bb15, ^bb16, ^bb19, ^bb20
    llvm.br ^bb21
  ^bb18:  // pred: ^bb14
    %67 = llvm.trunc %59 : i64 to i32
    %68 = llvm.trunc %43 : i64 to i32
    %69 = llvm.mul %68, %1 : i32
    %70 = llvm.add %69, %67 : i32
    %71 = llvm.getelementptr %23[%70] : (!llvm.ptr, i32) -> !llvm.ptr, f32
    %72 = llvm.ptrtoint %71 : !llvm.ptr to i64
    %73 = llvm.inttoptr %72 : i64 to !llvm.ptr
    %74 = llvm.load %73 {alignment = 4 : i64} : !llvm.ptr -> f32
    %75 = llvm.fcmp "oge" %74, %10 : f32
    llvm.cond_br %75, ^bb19, ^bb20
  ^bb19:  // pred: ^bb18
    %76 = llvm.fpext %74 : f32 to f64
    %77 = llvm.getelementptr %9[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %78 = llvm.call @printf(%77, %76) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb17
  ^bb20:  // pred: ^bb18
    %79 = llvm.fpext %74 : f32 to f64
    %80 = llvm.getelementptr %8[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<5 x i8>
    %81 = llvm.call @printf(%80, %79) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb17
  ^bb21:  // pred: ^bb17
    %82 = llvm.add %59, %20 : i64
    llvm.br ^bb13(%82 : i64)
  ^bb22:  // pred: ^bb13
    %83 = llvm.getelementptr %7[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %84 = llvm.call @printf(%83) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %53, ^bb23, ^bb9
  ^bb23:  // pred: ^bb22
    %85 = llvm.getelementptr %6[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %86 = llvm.call @printf(%85) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb9
  ^bb24:  // pred: ^bb9
    %87 = llvm.add %43, %20 : i64
    llvm.br ^bb5(%87 : i64)
  ^bb25:  // pred: ^bb5
    %88 = llvm.call @printf(%35) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %38, ^bb26, ^bb27
  ^bb26:  // pred: ^bb25
    %89 = llvm.getelementptr %4[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
    %90 = llvm.call @printf(%89) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb27
  ^bb27:  // 2 preds: ^bb25, ^bb26
    %91 = llvm.add %36, %20 : i64
    llvm.br ^bb1(%91 : i64)
  ^bb28:  // pred: ^bb1
    %92 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %93 = llvm.call @printf(%92) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_print_tensor_Tensorgenerico3441(%arg0: !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_print_tensor_Tensorgenerico3441(%arg0) : (!llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) -> ()
    llvm.return
  }
}
