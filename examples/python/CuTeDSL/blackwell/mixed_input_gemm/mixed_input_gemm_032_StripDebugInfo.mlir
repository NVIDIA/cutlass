gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_100a">] {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(512 : i32) : i32
    %1 = llvm.mlir.constant(1024 : i32) : i32
    %2 = llvm.mlir.constant(0 : i32) : i32
    %3 = llvm.mlir.constant(8 : i32) : i32
    %4 = llvm.mlir.constant(4 : i32) : i32
    %5 = llvm.mlir.constant(1 : i32) : i32
    %6 = llvm.alloca %4 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %7 = llvm.alloca %3 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %8 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %9 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %10 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %11 = llvm.extractvalue %10[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %12 = llvm.extractvalue %11[0] : !llvm.struct<(i32, i32, i32)> 
    %13 = llvm.extractvalue %11[1] : !llvm.struct<(i32, i32, i32)> 
    %14 = llvm.extractvalue %10[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %15 = llvm.extractvalue %14[0] : !llvm.struct<(i64, i64)> 
    %16 = llvm.extractvalue %14[1] : !llvm.struct<(i64, i64)> 
    %17 = llvm.sdiv %9, %12 : i32
    %18 = llvm.srem %9, %12 : i32
    %19 = llvm.mul %18, %1 : i32
    %20 = llvm.sdiv %17, %13 : i32
    %21 = llvm.srem %17, %13 : i32
    %22 = llvm.sext %21 : i32 to i64
    %23 = llvm.mul %22, %15 : i64
    %24 = llvm.sext %19 : i32 to i64
    %25 = llvm.add %24, %23 : i64
    %26 = llvm.sext %20 : i32 to i64
    %27 = llvm.mul %26, %16 : i64
    %28 = llvm.add %25, %27 : i64
    %29 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %30 = llvm.getelementptr %29[%28] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %31 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %32 = llvm.extractvalue %31[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %33 = llvm.extractvalue %32[0] : !llvm.struct<(i32, i32, i32)> 
    %34 = llvm.extractvalue %32[1] : !llvm.struct<(i32, i32, i32)> 
    %35 = llvm.extractvalue %31[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %36 = llvm.extractvalue %35[0] : !llvm.struct<(i64, i64)> 
    %37 = llvm.extractvalue %35[1] : !llvm.struct<(i64, i64)> 
    %38 = llvm.sdiv %9, %33 : i32
    %39 = llvm.srem %9, %33 : i32
    %40 = llvm.mul %39, %0 : i32
    %41 = llvm.sdiv %38, %34 : i32
    %42 = llvm.srem %38, %34 : i32
    %43 = llvm.sext %42 : i32 to i64
    %44 = llvm.mul %43, %36 : i64
    %45 = llvm.sext %40 : i32 to i64
    %46 = llvm.add %45, %44 : i64
    %47 = llvm.sext %41 : i32 to i64
    %48 = llvm.mul %47, %37 : i64
    %49 = llvm.add %46, %48 : i64
    %50 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %51 = llvm.getelementptr %50[%49] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %52 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %53 = llvm.extractvalue %52[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %54 = llvm.extractvalue %53[0] : !llvm.struct<(i32, i32, i32)> 
    %55 = llvm.extractvalue %53[1] : !llvm.struct<(i32, i32, i32)> 
    %56 = llvm.sdiv %9, %54 : i32
    %57 = llvm.srem %9, %54 : i32
    %58 = llvm.mul %57, %1 : i32
    %59 = llvm.sdiv %56, %55 : i32
    %60 = llvm.srem %56, %55 : i32
    %61 = llvm.mul %8, %3 : i32
    %62 = llvm.getelementptr %30[%61] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %63 = llvm.mul %8, %4 : i32
    %64 = llvm.getelementptr %51[%63] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %65 = llvm.add %58, %61 : i32
    %66 = llvm.icmp "slt" %65, %arg3 : i32
    %67 = llvm.icmp "slt" %60, %arg4 : i32
    %68 = llvm.and %66, %67 : i1
    %69 = llvm.icmp "slt" %59, %arg5 : i32
    %70 = llvm.and %68, %69 : i1
    llvm.cond_br %70, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %71 = llvm.getelementptr %62[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %72 = llvm.getelementptr %7[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %73 = llvm.getelementptr %62[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %74 = llvm.getelementptr %7[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %75 = llvm.getelementptr %62[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %76 = llvm.getelementptr %7[3] : (!llvm.ptr) -> !llvm.ptr, f32
    %77 = llvm.getelementptr %62[4] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %78 = llvm.getelementptr %7[4] : (!llvm.ptr) -> !llvm.ptr, f32
    %79 = llvm.getelementptr %62[5] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %80 = llvm.getelementptr %7[5] : (!llvm.ptr) -> !llvm.ptr, f32
    %81 = llvm.getelementptr %62[6] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %82 = llvm.getelementptr %7[6] : (!llvm.ptr) -> !llvm.ptr, f32
    %83 = llvm.getelementptr %62[7] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %84 = llvm.getelementptr %7[7] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%2 : i32)
  ^bb2(%85: i32):  // 2 preds: ^bb1, ^bb3
    %86 = llvm.icmp "slt" %85, %5 : i32
    llvm.cond_br %86, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %87 = llvm.load %62 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %87, %7 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %88 = llvm.load %71 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %88, %72 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %89 = llvm.load %73 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %89, %74 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %90 = llvm.load %75 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %90, %76 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %91 = llvm.load %77 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %91, %78 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %92 = llvm.load %79 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %92, %80 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %93 = llvm.load %81 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %93, %82 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %94 = llvm.load %83 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %94, %84 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %95 = llvm.add %85, %5 : i32
    llvm.br ^bb2(%95 : i32)
  ^bb4:  // pred: ^bb2
    %96 = llvm.load %7 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
    %97 = llvm.fptosi %96 : vector<8xf32> to vector<8xi4>
    %98 = llvm.bitcast %97 : vector<8xi4> to vector<4xi8>
    llvm.store %98, %6 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    %99 = llvm.getelementptr %6[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %100 = llvm.getelementptr %64[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %101 = llvm.getelementptr %6[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %102 = llvm.getelementptr %64[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %103 = llvm.getelementptr %6[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %104 = llvm.getelementptr %64[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    llvm.br ^bb5(%2 : i32)
  ^bb5(%105: i32):  // 2 preds: ^bb4, ^bb6
    %106 = llvm.icmp "slt" %105, %5 : i32
    llvm.cond_br %106, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %107 = llvm.load %6 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %107, %64 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %108 = llvm.load %99 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %108, %100 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %109 = llvm.load %101 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %109, %102 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %110 = llvm.load %103 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %110, %104 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %111 = llvm.add %105, %5 : i32
    llvm.br ^bb5(%111 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
