gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_100a">] {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
    %39 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %40 = llvm.extractvalue %39[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %41 = llvm.extractvalue %40[0] : !llvm.struct<(i32, i32, i32)> 
    %42 = llvm.extractvalue %40[1] : !llvm.struct<(i32, i32, i32)> 
    %43 = llvm.extractvalue %39[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %44 = llvm.extractvalue %43[0] : !llvm.struct<(i64, i64)> 
    %45 = llvm.extractvalue %43[1] : !llvm.struct<(i64, i64)> 
    %46 = llvm.sdiv %17, %41 : i32
    %47 = llvm.srem %17, %41 : i32
    %48 = llvm.sext %47 : i32 to i64
    %49 = llvm.mul %48, %44 : i64
    %50 = llvm.sdiv %46, %42 : i32
    %51 = llvm.srem %46, %42 : i32
    %52 = llvm.mul %51, %6 : i32
    %53 = llvm.sext %52 : i32 to i64
    %54 = llvm.add %49, %53 : i64
    %55 = llvm.sext %50 : i32 to i64
    %56 = llvm.mul %55, %45 : i64
    %57 = llvm.add %54, %56 : i64
    %58 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %59 = llvm.getelementptr %58[%57] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %60 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %61 = llvm.extractvalue %60[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %62 = llvm.extractvalue %61[0] : !llvm.struct<(i32, i32, i32)> 
    %63 = llvm.extractvalue %61[1] : !llvm.struct<(i32, i32, i32)> 
    %64 = llvm.sdiv %17, %62 : i32
    %65 = llvm.srem %17, %62 : i32
    %66 = llvm.sdiv %64, %63 : i32
    %67 = llvm.srem %64, %63 : i32
    %68 = llvm.mul %67, %6 : i32
    %69 = llvm.mul %19, %7 : i64
    %70 = llvm.insertvalue %69, %5[0] : !llvm.struct<(i64, i64)> 
    %71 = llvm.insertvalue %19, %70[1] : !llvm.struct<(i64, i64)> 
    %72 = llvm.insertvalue %11, %4[0] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %73 = llvm.insertvalue %71, %72[1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %74 = llvm.extractvalue %73[1, 1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %75 = llvm.sext %16 : i32 to i64
    %76 = llvm.mul %75, %69 : i64
    %77 = llvm.getelementptr %38[%76] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %78 = llvm.mul %16, %12 : i32
    %79 = llvm.getelementptr %59[%78] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %80 = llvm.add %68, %78 : i32
    %81 = llvm.icmp "slt" %65, %arg3 : i32
    %82 = llvm.icmp "slt" %80, %arg4 : i32
    %83 = llvm.and %81, %82 : i1
    %84 = llvm.icmp "slt" %66, %arg5 : i32
    %85 = llvm.and %83, %84 : i1
    llvm.cond_br %85, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %86 = llvm.getelementptr %77[%74] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %87 = llvm.getelementptr %15[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %88 = llvm.mul %74, %9 : i64
    %89 = llvm.getelementptr %77[%88] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %90 = llvm.getelementptr %15[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %91 = llvm.mul %74, %10 : i64
    %92 = llvm.getelementptr %77[%91] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %93 = llvm.getelementptr %15[3] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%8 : i32)
  ^bb2(%94: i32):  // 2 preds: ^bb1, ^bb3
    %95 = llvm.icmp "slt" %94, %13 : i32
    llvm.cond_br %95, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %96 = llvm.load %77 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %96, %15 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %97 = llvm.load %86 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %97, %87 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %98 = llvm.load %89 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %98, %90 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %99 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %99, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %100 = llvm.add %94, %13 : i32
    llvm.br ^bb2(%100 : i32)
  ^bb4:  // pred: ^bb2
    %101 = llvm.load %15 {alignment = 32 : i64} : !llvm.ptr -> vector<4xf32>
    %102 = llvm.bitcast %101 : vector<4xf32> to vector<4xi32>
    %103 = llvm.extractelement %102[%9 : i64] : vector<4xi32>
    %104 = llvm.extractelement %102[%10 : i64] : vector<4xi32>
    %105 = llvm.bitcast %103 : i32 to f32
    %106 = llvm.bitcast %104 : i32 to f32
    %107 = nvvm.cvt.packfloat.f32 %106, %105, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %108 = llvm.or %8, %107 : i32
    %109 = llvm.extractelement %102[%1 : i64] : vector<4xi32>
    %110 = llvm.extractelement %102[%0 : i64] : vector<4xi32>
    %111 = llvm.bitcast %109 : i32 to f32
    %112 = llvm.bitcast %110 : i32 to f32
    %113 = nvvm.cvt.packfloat.f32 %112, %111, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %114 = llvm.shl %108, %2 : i32
    %115 = llvm.or %114, %113 : i32
    %116 = llvm.insertelement %115, %3[%1 : i64] : vector<1xi32>
    %117 = llvm.bitcast %116 : vector<1xi32> to vector<4xi8>
    llvm.store %117, %14 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    %118 = llvm.getelementptr %14[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %119 = llvm.getelementptr %79[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %120 = llvm.getelementptr %14[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %121 = llvm.getelementptr %79[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %122 = llvm.getelementptr %14[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %123 = llvm.getelementptr %79[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    llvm.br ^bb5(%8 : i32)
  ^bb5(%124: i32):  // 2 preds: ^bb4, ^bb6
    %125 = llvm.icmp "slt" %124, %13 : i32
    llvm.cond_br %125, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %126 = llvm.load %14 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %126, %79 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %127 = llvm.load %118 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %127, %119 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %128 = llvm.load %120 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %128, %121 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %129 = llvm.load %122 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %129, %123 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %130 = llvm.add %124, %13 : i32
    llvm.br ^bb5(%130 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
