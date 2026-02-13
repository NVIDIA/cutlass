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
    %25 = builtin.unrealized_conversion_cast %24 : !llvm.ptr to !cute.ptr<f32, generic>
    %26 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
    %27 = llvm.insertvalue %24, %26[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %28 = llvm.insertvalue %23, %27[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %29 = builtin.unrealized_conversion_cast %25 : !cute.ptr<f32, generic> to !llvm.ptr
    %30 = llvm.ptrtoint %29 : !llvm.ptr to i64
    %31 = llvm.getelementptr %22[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<72 x i8>
    %32 = llvm.call @printf(%31, %30) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %33 = llvm.mlir.constant(3 : i32) : i32
    %34 = llvm.mlir.constant(4 : i32) : i32
    %35 = llvm.mlir.constant(1 : i32) : i32
    %36 = llvm.sext %33 : i32 to i64
    %37 = llvm.sext %34 : i32 to i64
    %38 = llvm.sext %35 : i32 to i64
    %39 = llvm.getelementptr %16[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %40 = llvm.call @printf(%39) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %41 = llvm.sub %38, %17 : i64
    %42 = llvm.getelementptr %14[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %43 = llvm.sub %36, %12 : i64
    %44 = llvm.getelementptr %2[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    llvm.br ^bb1(%18 : i64)
  ^bb1(%45: i64):  // 2 preds: ^bb0, ^bb29
    %46 = llvm.icmp "slt" %45, %38 : i64
    llvm.cond_br %46, ^bb2, ^bb30
  ^bb2:  // pred: ^bb1
    %47 = llvm.icmp "ne" %45, %41 : i64
    %48 = llvm.icmp "ne" %45, %18 : i64
    llvm.cond_br %48, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    %49 = llvm.getelementptr %15[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<8 x i8>
    %50 = llvm.call @printf(%49) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %51 = llvm.call @printf(%42) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb5(%18 : i64)
  ^bb5(%52: i64):  // 2 preds: ^bb4, ^bb26
    %53 = llvm.icmp "slt" %52, %36 : i64
    llvm.cond_br %53, ^bb6, ^bb27
  ^bb6:  // pred: ^bb5
    %54 = llvm.icmp "sgt" %52, %13 : i64
    %55 = llvm.icmp "slt" %52, %43 : i64
    %56 = llvm.and %54, %55 : i1
    llvm.cond_br %56, ^bb7, ^bb10
  ^bb7:  // pred: ^bb6
    %57 = llvm.icmp "eq" %52, %12 : i64
    llvm.cond_br %57, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %58 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
    %59 = llvm.call @printf(%58) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb9
  ^bb9:  // 2 preds: ^bb7, ^bb8
    llvm.br ^bb26
  ^bb10:  // pred: ^bb6
    %60 = llvm.icmp "ne" %52, %18 : i64
    %61 = llvm.sub %36, %17 : i64
    %62 = llvm.icmp "slt" %52, %61 : i64
    llvm.cond_br %60, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    %63 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<9 x i8>
    %64 = llvm.call @printf(%63) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %65 = llvm.getelementptr %9[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %66 = llvm.call @printf(%65) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    %67 = llvm.sub %37, %12 : i64
    llvm.br ^bb13(%18 : i64)
  ^bb13(%68: i64):  // 2 preds: ^bb12, ^bb22
    %69 = llvm.icmp "slt" %68, %37 : i64
    llvm.cond_br %69, ^bb14, ^bb23
  ^bb14:  // pred: ^bb13
    %70 = llvm.icmp "sgt" %68, %13 : i64
    %71 = llvm.icmp "slt" %68, %67 : i64
    %72 = llvm.and %70, %71 : i1
    llvm.cond_br %72, ^bb15, ^bb18
  ^bb15:  // pred: ^bb14
    %73 = llvm.icmp "eq" %68, %12 : i64
    llvm.cond_br %73, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %74 = llvm.getelementptr %8[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %75 = llvm.call @printf(%74) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    llvm.br ^bb22
  ^bb18:  // pred: ^bb14
    %76 = llvm.trunc %45 : i64 to i32
    %77 = llvm.trunc %68 : i64 to i32
    %78 = llvm.trunc %52 : i64 to i32
    %79 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %80 = llvm.insertvalue %78, %79[0] : !llvm.struct<(i32, i32, i32)> 
    %81 = llvm.insertvalue %77, %80[1] : !llvm.struct<(i32, i32, i32)> 
    %82 = llvm.insertvalue %76, %81[2] : !llvm.struct<(i32, i32, i32)> 
    %83 = llvm.extractvalue %28[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %84 = llvm.extractvalue %83[0] : !llvm.struct<(struct<()>, struct<()>)> 
    %85 = llvm.extractvalue %83[1] : !llvm.struct<(struct<()>, struct<()>)> 
    %86 = llvm.extractvalue %82[0] : !llvm.struct<(i32, i32, i32)> 
    %87 = llvm.extractvalue %82[1] : !llvm.struct<(i32, i32, i32)> 
    %88 = llvm.extractvalue %82[2] : !llvm.struct<(i32, i32, i32)> 
    %89 = llvm.mlir.constant(4 : i32) : i32
    %90 = llvm.mul %86, %89 : i32
    %91 = llvm.add %90, %87 : i32
    %92 = llvm.extractvalue %28[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
    %93 = llvm.getelementptr %92[%91] : (!llvm.ptr, i32) -> !llvm.ptr, f32
    %94 = llvm.ptrtoint %93 : !llvm.ptr to i64
    %95 = llvm.inttoptr %94 : i64 to !llvm.ptr
    %96 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr -> f32
    %97 = llvm.fcmp "oge" %96, %7 : f32
    llvm.cond_br %97, ^bb19, ^bb20
  ^bb19:  // pred: ^bb18
    %98 = llvm.fpext %96 : f32 to f64
    %99 = llvm.getelementptr %6[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<6 x i8>
    %100 = llvm.call @printf(%99, %98) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb21
  ^bb20:  // pred: ^bb18
    %101 = llvm.fpext %96 : f32 to f64
    %102 = llvm.getelementptr %5[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<5 x i8>
    %103 = llvm.call @printf(%102, %101) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
    llvm.br ^bb21
  ^bb21:  // 2 preds: ^bb19, ^bb20
    llvm.br ^bb22
  ^bb22:  // 2 preds: ^bb17, ^bb21
    %104 = llvm.add %68, %17 : i64
    llvm.br ^bb13(%104 : i64)
  ^bb23:  // pred: ^bb13
    %105 = llvm.getelementptr %4[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<2 x i8>
    %106 = llvm.call @printf(%105) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %62, ^bb24, ^bb25
  ^bb24:  // pred: ^bb23
    %107 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %108 = llvm.call @printf(%107) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb25
  ^bb25:  // 2 preds: ^bb23, ^bb24
    llvm.br ^bb26
  ^bb26:  // 2 preds: ^bb9, ^bb25
    %109 = llvm.add %52, %17 : i64
    llvm.br ^bb5(%109 : i64)
  ^bb27:  // pred: ^bb5
    %110 = llvm.call @printf(%44) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.cond_br %47, ^bb28, ^bb29
  ^bb28:  // pred: ^bb27
    %111 = llvm.getelementptr %1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
    %112 = llvm.call @printf(%111) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.br ^bb29
  ^bb29:  // 2 preds: ^bb27, ^bb28
    %113 = llvm.add %45, %17 : i64
    llvm.br ^bb1(%113 : i64)
  ^bb30:  // pred: ^bb1
    %114 = llvm.getelementptr %0[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<3 x i8>
    %115 = llvm.call @printf(%114) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_print_tensor_Tensorgenerico3441(%arg0: !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_print_tensor_Tensorgenerico3441(%arg0) : (!llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>) -> ()
    llvm.return
  }
}
