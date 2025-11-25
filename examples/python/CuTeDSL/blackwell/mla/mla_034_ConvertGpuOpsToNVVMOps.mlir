gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_100a">] {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.mlir.constant(0 : i64) : i64
    %2 = llvm.mlir.constant(16 : i32) : i32
    %3 = llvm.mlir.undef : vector<1xi32>
    %4 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(i64, i64)>)>
    %5 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %6 = llvm.mlir.constant(512 : i32) : i32
    %7 = llvm.mlir.constant(4 : i64) : i64
    %8 = llvm.mlir.constant(0 : i32) : i32
    %9 = llvm.mlir.constant(2 : i64) : i64
    %10 = llvm.mlir.constant(3 : i64) : i64
    %11 = llvm.mlir.poison : !llvm.struct<()>
    %12 = llvm.mlir.constant(4 : i32) : i32
    %13 = llvm.mlir.constant(1 : i32) : i32
    %14 = llvm.alloca %12 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %15 = llvm.alloca %12 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %16 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %17 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %18 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)> 
    %19 = llvm.extractvalue %18[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %20 = llvm.extractvalue %18[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %21 = llvm.extractvalue %20[0] : !llvm.struct<(i32, i32, i32)> 
    %22 = llvm.extractvalue %20[1] : !llvm.struct<(i32, i32, i32)> 
    %23 = llvm.extractvalue %18[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %24 = llvm.extractvalue %23[1] : !llvm.struct<(i64, i64, i64)> 
    %25 = llvm.extractvalue %23[2] : !llvm.struct<(i64, i64, i64)> 
    %26 = llvm.sdiv %17, %21 : i32
    %27 = llvm.srem %17, %21 : i32
    %28 = llvm.sext %27 : i32 to i64
    %29 = llvm.mul %28, %24 : i64
    %30 = llvm.sdiv %26, %22 : i32
    %31 = llvm.srem %26, %22 : i32
    %32 = llvm.sext %31 : i32 to i64
    %33 = llvm.mul %32, %25 : i64
    %34 = llvm.add %29, %33 : i64
    %35 = llvm.sext %30 : i32 to i64
    %36 = llvm.add %34, %35 : i64
    %37 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)> 
    %38 = llvm.getelementptr %37[%36] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %39 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)> 
    %40 = llvm.extractvalue %39[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)> 
    %41 = llvm.extractvalue %40[0] : !llvm.struct<(i32, i32, i32)> 
    %42 = llvm.extractvalue %40[1] : !llvm.struct<(i32, i32, i32)> 
    %43 = llvm.extractvalue %39[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)> 
    %44 = llvm.extractvalue %43[0] : !llvm.struct<(i32, i32)> 
    %45 = llvm.extractvalue %43[1] : !llvm.struct<(i32, i32)> 
    %46 = llvm.sdiv %17, %41 : i32
    %47 = llvm.srem %17, %41 : i32
    %48 = llvm.mul %47, %44 : i32
    %49 = llvm.sdiv %46, %42 : i32
    %50 = llvm.srem %46, %42 : i32
    %51 = llvm.mul %50, %6 : i32
    %52 = llvm.add %48, %51 : i32
    %53 = llvm.mul %49, %45 : i32
    %54 = llvm.add %52, %53 : i32
    %55 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)> 
    %56 = llvm.getelementptr %55[%54] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %57 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %58 = llvm.extractvalue %57[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %59 = llvm.extractvalue %58[0] : !llvm.struct<(i32, i32, i32)> 
    %60 = llvm.extractvalue %58[1] : !llvm.struct<(i32, i32, i32)> 
    %61 = llvm.sdiv %17, %59 : i32
    %62 = llvm.srem %17, %59 : i32
    %63 = llvm.sdiv %61, %60 : i32
    %64 = llvm.srem %61, %60 : i32
    %65 = llvm.mul %64, %6 : i32
    %66 = llvm.mul %19, %7 : i64
    %67 = llvm.insertvalue %66, %5[0] : !llvm.struct<(i64, i64)> 
    %68 = llvm.insertvalue %19, %67[1] : !llvm.struct<(i64, i64)> 
    %69 = llvm.insertvalue %11, %4[0] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %70 = llvm.insertvalue %68, %69[1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %71 = llvm.extractvalue %70[1, 1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %72 = llvm.sext %16 : i32 to i64
    %73 = llvm.mul %72, %66 : i64
    %74 = llvm.getelementptr %38[%73] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %75 = llvm.mul %16, %12 : i32
    %76 = llvm.getelementptr %56[%75] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %77 = llvm.add %65, %75 : i32
    %78 = llvm.icmp "slt" %62, %arg3 : i32
    %79 = llvm.icmp "slt" %77, %arg4 : i32
    %80 = llvm.and %78, %79 : i1
    %81 = llvm.icmp "slt" %63, %arg5 : i32
    %82 = llvm.and %80, %81 : i1
    llvm.cond_br %82, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %83 = llvm.getelementptr %74[%71] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %84 = llvm.getelementptr %15[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %85 = llvm.mul %71, %9 : i64
    %86 = llvm.getelementptr %74[%85] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %87 = llvm.getelementptr %15[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %88 = llvm.mul %71, %10 : i64
    %89 = llvm.getelementptr %74[%88] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %90 = llvm.getelementptr %15[3] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%8 : i32)
  ^bb2(%91: i32):  // 2 preds: ^bb1, ^bb3
    %92 = llvm.icmp "slt" %91, %13 : i32
    llvm.cond_br %92, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %93 = llvm.load %74 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %93, %15 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %94 = llvm.load %83 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %94, %84 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %95 = llvm.load %86 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %95, %87 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %96 = llvm.load %89 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %96, %90 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %97 = llvm.add %91, %13 : i32
    llvm.br ^bb2(%97 : i32)
  ^bb4:  // pred: ^bb2
    %98 = llvm.load %15 {alignment = 32 : i64} : !llvm.ptr -> vector<4xf32>
    %99 = llvm.bitcast %98 : vector<4xf32> to vector<4xi32>
    %100 = llvm.extractelement %99[%9 : i64] : vector<4xi32>
    %101 = llvm.extractelement %99[%10 : i64] : vector<4xi32>
    %102 = llvm.bitcast %100 : i32 to f32
    %103 = llvm.bitcast %101 : i32 to f32
    %104 = nvvm.cvt.packfloat.f32 %103, %102, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %105 = llvm.or %8, %104 : i32
    %106 = llvm.extractelement %99[%1 : i64] : vector<4xi32>
    %107 = llvm.extractelement %99[%0 : i64] : vector<4xi32>
    %108 = llvm.bitcast %106 : i32 to f32
    %109 = llvm.bitcast %107 : i32 to f32
    %110 = nvvm.cvt.packfloat.f32 %109, %108, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %111 = llvm.shl %105, %2 : i32
    %112 = llvm.or %111, %110 : i32
    %113 = llvm.insertelement %112, %3[%1 : i64] : vector<1xi32>
    %114 = llvm.bitcast %113 : vector<1xi32> to vector<4xi8>
    llvm.store %114, %14 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    llvm.br ^bb5(%8 : i32)
  ^bb5(%115: i32):  // 2 preds: ^bb4, ^bb6
    %116 = llvm.icmp "slt" %115, %13 : i32
    llvm.cond_br %116, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %117 = llvm.load %14 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
    llvm.store %117, %76 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
    %118 = llvm.add %115, %13 : i32
    llvm.br ^bb5(%118 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
