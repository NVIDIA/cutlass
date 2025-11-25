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
  llvm.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.addressof @printfFormat_14 : !llvm.ptr
    %1 = llvm.mlir.addressof @printfFormat_13 : !llvm.ptr
    %2 = llvm.mlir.addressof @printfFormat_12 : !llvm.ptr
    %3 = llvm.mlir.addressof @printfFormat_11 : !llvm.ptr
    %4 = llvm.mlir.addressof @printfFormat_10 : !llvm.ptr
    %5 = llvm.mlir.addressof @printfFormat_9 : !llvm.ptr
    %6 = llvm.mlir.addressof @printfFormat_8 : !llvm.ptr
    %7 = llvm.mlir.constant(0.000000e+00 : f32) : f32
    %8 = llvm.mlir.addressof @printfFormat_7 : !llvm.ptr
    %9 = llvm.mlir.addressof @printfFormat_6 : !llvm.ptr
    %10 = llvm.mlir.addressof @printfFormat_5 : !llvm.ptr
    %11 = llvm.mlir.addressof @printfFormat_4 : !llvm.ptr
    %12 = llvm.mlir.constant(3 : index) : i64
    %13 = llvm.mlir.constant(2 : index) : i64
    %14 = llvm.mlir.addressof @printfFormat_3 : !llvm.ptr
    %15 = llvm.mlir.addressof @printfFormat_2 : !llvm.ptr
    %16 = llvm.mlir.addressof @printfFormat_1 : !llvm.ptr
    %17 = llvm.mlir.constant(1 : index) : i64
    %18 = llvm.mlir.constant(0 : index) : i64
    %19 = llvm.mlir.poison : !llvm.struct<()>
    %20 = llvm.mlir.poison : !llvm.struct<()>
    %21 = llvm.mlir.poison : !llvm.struct<()>
    %22 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %23 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
    %24 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %25 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
    %26 = llvm.insertvalue %24, %25[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %27 = llvm.insertvalue %23, %26[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %28 = llvm.ptrtoint %24 : !llvm.ptr to i64
    %29 = llvm.getelementptr %22[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<72 x i8>
    %30 = llvm.call @printf(%29, %28) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %31 = llvm.mlir.constant(3 : i32) : i32
    %32 = llvm.mlir.constant(4 : i32) : i32
    %33 = llvm.mlir.constant(1 : i32) : i32
    %34 = llvm.sext %31 : i32 to i64
    %35 = llvm.sext %32 : i32 to i64
    %36 = llvm.sext %33 : i32 to i64
    %37 = llvm.getelementptr %16[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %38 = llvm.call @printf(%37) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %39 = llvm.sub %36, %17 : i64
    %40 = llvm.getelementptr %14[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %41 = llvm.sub %34, %12 : i64
    %42 = llvm.getelementptr %2[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    llvm.br ^bb1(%18 : i64)
  ^bb1(%43: i64):  // 2 preds: ^bb0, ^bb29
    %44 = llvm.icmp "slt" %43, %36 : i64
    llvm.cond_br %44, ^bb2, ^bb30
  ^bb2:  // pred: ^bb1
    %45 = llvm.icmp "ne" %43, %39 : i64
    %46 = llvm.icmp "ne" %43, %18 : i64
    llvm.cond_br %46, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    %47 = llvm.getelementptr %15[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %48 = llvm.call @printf(%47) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %49 = llvm.call @printf(%40) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb5(%18 : i64)
  ^bb5(%50: i64):  // 2 preds: ^bb4, ^bb26
    %51 = llvm.icmp "slt" %50, %34 : i64
    llvm.cond_br %51, ^bb6, ^bb27
  ^bb6:  // pred: ^bb5
    %52 = llvm.icmp "sgt" %50, %13 : i64
    %53 = llvm.icmp "slt" %50, %41 : i64
    %54 = llvm.and %52, %53 : i1
    llvm.cond_br %54, ^bb7, ^bb10
  ^bb7:  // pred: ^bb6
    %55 = llvm.icmp "eq" %50, %12 : i64
    llvm.cond_br %55, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %56 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
    %57 = llvm.call @printf(%56) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb9
  ^bb9:  // 2 preds: ^bb7, ^bb8
    llvm.br ^bb26
  ^bb10:  // pred: ^bb6
    %58 = llvm.icmp "ne" %50, %18 : i64
    %59 = llvm.sub %34, %17 : i64
    %60 = llvm.icmp "slt" %50, %59 : i64
    llvm.cond_br %58, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    %61 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<9 x i8>
    %62 = llvm.call @printf(%61) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %63 = llvm.getelementptr %9[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %64 = llvm.call @printf(%63) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %65 = llvm.sub %35, %12 : i64
    llvm.br ^bb13(%18 : i64)
  ^bb13(%66: i64):  // 2 preds: ^bb12, ^bb22
    %67 = llvm.icmp "slt" %66, %35 : i64
    llvm.cond_br %67, ^bb14, ^bb23
  ^bb14:  // pred: ^bb13
    %68 = llvm.icmp "sgt" %66, %13 : i64
    %69 = llvm.icmp "slt" %66, %65 : i64
    %70 = llvm.and %68, %69 : i1
    llvm.cond_br %70, ^bb15, ^bb18
  ^bb15:  // pred: ^bb14
    %71 = llvm.icmp "eq" %66, %12 : i64
    llvm.cond_br %71, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %72 = llvm.getelementptr %8[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %73 = llvm.call @printf(%72) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    llvm.br ^bb22
  ^bb18:  // pred: ^bb14
    %74 = llvm.trunc %43 : i64 to i32
    %75 = llvm.trunc %66 : i64 to i32
    %76 = llvm.trunc %50 : i64 to i32
    %77 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %78 = llvm.insertvalue %76, %77[0] : !llvm.struct<(i32, i32, i32)> 
    %79 = llvm.insertvalue %75, %78[1] : !llvm.struct<(i32, i32, i32)> 
    %80 = llvm.insertvalue %74, %79[2] : !llvm.struct<(i32, i32, i32)> 
    %81 = llvm.extractvalue %27[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %82 = llvm.extractvalue %81[0] : !llvm.struct<(struct<()>, struct<()>)> 
    %83 = llvm.extractvalue %81[1] : !llvm.struct<(struct<()>, struct<()>)> 
    %84 = llvm.extractvalue %80[0] : !llvm.struct<(i32, i32, i32)> 
    %85 = llvm.extractvalue %80[1] : !llvm.struct<(i32, i32, i32)> 
    %86 = llvm.extractvalue %80[2] : !llvm.struct<(i32, i32, i32)> 
    %87 = llvm.mlir.constant(4 : i32) : i32
    %88 = llvm.mul %84, %87 : i32
    %89 = llvm.add %88, %85 : i32
    %90 = llvm.extractvalue %27[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %91 = llvm.getelementptr %90[%89] : (!llvm.ptr, i32) -> !llvm.ptr, f32
    %92 = llvm.ptrtoint %91 : !llvm.ptr to i64
    %93 = llvm.inttoptr %92 : i64 to !llvm.ptr
    %94 = llvm.load %93 {alignment = 4 : i64} : !llvm.ptr -> f32
    %95 = llvm.fcmp "oge" %94, %7 : f32
    llvm.cond_br %95, ^bb19, ^bb20
  ^bb19:  // pred: ^bb18
    %96 = llvm.fpext %94 : f32 to f64
    %97 = llvm.getelementptr %6[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %98 = llvm.call @printf(%97, %96) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb21
  ^bb20:  // pred: ^bb18
    %99 = llvm.fpext %94 : f32 to f64
    %100 = llvm.getelementptr %5[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<5 x i8>
    %101 = llvm.call @printf(%100, %99) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb21
  ^bb21:  // 2 preds: ^bb19, ^bb20
    llvm.br ^bb22
  ^bb22:  // 2 preds: ^bb17, ^bb21
    %102 = llvm.add %66, %17 : i64
    llvm.br ^bb13(%102 : i64)
  ^bb23:  // pred: ^bb13
    %103 = llvm.getelementptr %4[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %104 = llvm.call @printf(%103) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %60, ^bb24, ^bb25
  ^bb24:  // pred: ^bb23
    %105 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %106 = llvm.call @printf(%105) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb25
  ^bb25:  // 2 preds: ^bb23, ^bb24
    llvm.br ^bb26
  ^bb26:  // 2 preds: ^bb9, ^bb25
    %107 = llvm.add %50, %17 : i64
    llvm.br ^bb5(%107 : i64)
  ^bb27:  // pred: ^bb5
    %108 = llvm.call @printf(%42) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %45, ^bb28, ^bb29
  ^bb28:  // pred: ^bb27
    %109 = llvm.getelementptr %1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
    %110 = llvm.call @printf(%109) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb29
  ^bb29:  // 2 preds: ^bb27, ^bb28
    %111 = llvm.add %43, %17 : i64
    llvm.br ^bb1(%111 : i64)
  ^bb30:  // pred: ^bb1
    %112 = llvm.getelementptr %0[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %113 = llvm.call @printf(%112) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_print_tensor_Tensorgenerico3441(%arg0: !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_print_tensor_Tensorgenerico3441(%arg0) : (!llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) -> ()
    llvm.return
  }
}
