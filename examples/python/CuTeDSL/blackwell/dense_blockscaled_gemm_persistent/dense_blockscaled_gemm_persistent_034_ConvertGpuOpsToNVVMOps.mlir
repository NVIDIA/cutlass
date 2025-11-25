gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_100a">] {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.mlir.constant(0 : i64) : i64
    %2 = llvm.mlir.undef : vector<1xi32>
    %3 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(i64, i64)>)>
    %4 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %5 = llvm.mlir.constant(1024 : i32) : i32
    %6 = llvm.mlir.constant(512 : i32) : i32
    %7 = llvm.mlir.constant(8 : i64) : i64
    %8 = llvm.mlir.constant(0 : i32) : i32
    %9 = llvm.mlir.constant(2 : i64) : i64
    %10 = llvm.mlir.constant(3 : i64) : i64
    %11 = llvm.mlir.constant(4 : i64) : i64
    %12 = llvm.mlir.constant(5 : i64) : i64
    %13 = llvm.mlir.constant(6 : i64) : i64
    %14 = llvm.mlir.constant(7 : i64) : i64
    %15 = llvm.mlir.poison : !llvm.struct<()>
    %16 = llvm.mlir.constant(8 : i32) : i32
    %17 = llvm.mlir.constant(4 : i32) : i32
    %18 = llvm.mlir.constant(1 : i32) : i32
    %19 = llvm.alloca %17 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %20 = llvm.alloca %16 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %21 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %22 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %23 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)> 
    %24 = llvm.extractvalue %23[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %25 = llvm.extractvalue %23[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %26 = llvm.extractvalue %25[0] : !llvm.struct<(i32, i32, i32)> 
    %27 = llvm.extractvalue %25[1] : !llvm.struct<(i32, i32, i32)> 
    %28 = llvm.extractvalue %23[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)> 
    %29 = llvm.extractvalue %28[1] : !llvm.struct<(i64, i64, i64)> 
    %30 = llvm.extractvalue %28[2] : !llvm.struct<(i64, i64, i64)> 
    %31 = llvm.sdiv %22, %26 : i32
    %32 = llvm.srem %22, %26 : i32
    %33 = llvm.sext %32 : i32 to i64
    %34 = llvm.mul %33, %29 : i64
    %35 = llvm.sdiv %31, %27 : i32
    %36 = llvm.srem %31, %27 : i32
    %37 = llvm.sext %36 : i32 to i64
    %38 = llvm.mul %37, %30 : i64
    %39 = llvm.add %34, %38 : i64
    %40 = llvm.sext %35 : i32 to i64
    %41 = llvm.add %39, %40 : i64
    %42 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64, i64)>)>)> 
    %43 = llvm.getelementptr %42[%41] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %44 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %45 = llvm.extractvalue %44[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %46 = llvm.extractvalue %45[0] : !llvm.struct<(i32, i32, i32)> 
    %47 = llvm.extractvalue %45[1] : !llvm.struct<(i32, i32, i32)> 
    %48 = llvm.extractvalue %44[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %49 = llvm.extractvalue %48[0] : !llvm.struct<(i64, i64)> 
    %50 = llvm.extractvalue %48[1] : !llvm.struct<(i64, i64)> 
    %51 = llvm.sdiv %22, %46 : i32
    %52 = llvm.srem %22, %46 : i32
    %53 = llvm.sext %52 : i32 to i64
    %54 = llvm.mul %53, %49 : i64
    %55 = llvm.sdiv %51, %47 : i32
    %56 = llvm.srem %51, %47 : i32
    %57 = llvm.mul %56, %6 : i32
    %58 = llvm.sext %57 : i32 to i64
    %59 = llvm.add %54, %58 : i64
    %60 = llvm.sext %55 : i32 to i64
    %61 = llvm.mul %60, %50 : i64
    %62 = llvm.add %59, %61 : i64
    %63 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %64 = llvm.getelementptr %63[%62] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %65 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %66 = llvm.extractvalue %65[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %67 = llvm.extractvalue %66[0] : !llvm.struct<(i32, i32, i32)> 
    %68 = llvm.extractvalue %66[1] : !llvm.struct<(i32, i32, i32)> 
    %69 = llvm.sdiv %22, %67 : i32
    %70 = llvm.srem %22, %67 : i32
    %71 = llvm.sdiv %69, %68 : i32
    %72 = llvm.srem %69, %68 : i32
    %73 = llvm.mul %72, %5 : i32
    %74 = llvm.mul %24, %7 : i64
    %75 = llvm.insertvalue %74, %4[0] : !llvm.struct<(i64, i64)> 
    %76 = llvm.insertvalue %24, %75[1] : !llvm.struct<(i64, i64)> 
    %77 = llvm.insertvalue %15, %3[0] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %78 = llvm.insertvalue %76, %77[1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %79 = llvm.extractvalue %78[1, 1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %80 = llvm.sext %21 : i32 to i64
    %81 = llvm.mul %80, %74 : i64
    %82 = llvm.getelementptr %43[%81] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %83 = llvm.mul %21, %17 : i32
    %84 = llvm.getelementptr %64[%83] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %85 = llvm.mul %21, %16 : i32
    %86 = llvm.add %73, %85 : i32
    %87 = llvm.icmp "slt" %70, %arg3 : i32
    %88 = llvm.icmp "slt" %86, %arg4 : i32
    %89 = llvm.and %87, %88 : i1
    %90 = llvm.icmp "slt" %71, %arg5 : i32
    %91 = llvm.and %89, %90 : i1
    llvm.cond_br %91, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %92 = llvm.getelementptr %82[%79] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %93 = llvm.getelementptr %20[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %94 = llvm.mul %79, %9 : i64
    %95 = llvm.getelementptr %82[%94] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %96 = llvm.getelementptr %20[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %97 = llvm.mul %79, %10 : i64
    %98 = llvm.getelementptr %82[%97] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %99 = llvm.getelementptr %20[3] : (!llvm.ptr) -> !llvm.ptr, f32
    %100 = llvm.mul %79, %11 : i64
    %101 = llvm.getelementptr %82[%100] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %102 = llvm.getelementptr %20[4] : (!llvm.ptr) -> !llvm.ptr, f32
    %103 = llvm.mul %79, %12 : i64
    %104 = llvm.getelementptr %82[%103] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %105 = llvm.getelementptr %20[5] : (!llvm.ptr) -> !llvm.ptr, f32
    %106 = llvm.mul %79, %13 : i64
    %107 = llvm.getelementptr %82[%106] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %108 = llvm.getelementptr %20[6] : (!llvm.ptr) -> !llvm.ptr, f32
    %109 = llvm.mul %79, %14 : i64
    %110 = llvm.getelementptr %82[%109] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %111 = llvm.getelementptr %20[7] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%8 : i32)
  ^bb2(%112: i32):  // 2 preds: ^bb1, ^bb3
    %113 = llvm.icmp "slt" %112, %18 : i32
    llvm.cond_br %113, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %114 = llvm.load %82 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %114, %20 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %115 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %115, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %116 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %116, %96 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %117 = llvm.load %98 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %117, %99 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %118 = llvm.load %101 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %118, %102 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %119 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %119, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %120 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %120, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %121 = llvm.load %110 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %121, %111 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %122 = llvm.add %112, %18 : i32
    llvm.br ^bb2(%122 : i32)
  ^bb4:  // pred: ^bb2
    %123 = llvm.load %20 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
    %124 = llvm.bitcast %123 : vector<8xf32> to vector<8xi32>
    %125 = llvm.extractelement %124[%13 : i64] : vector<8xi32>
    %126 = llvm.extractelement %124[%14 : i64] : vector<8xi32>
    %127 = llvm.bitcast %125 : i32 to f32
    %128 = llvm.bitcast %126 : i32 to f32
    %129 = nvvm.cvt.packfloat.f32 %128, %127, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %130 = llvm.or %8, %129 : i32
    %131 = llvm.extractelement %124[%11 : i64] : vector<8xi32>
    %132 = llvm.extractelement %124[%12 : i64] : vector<8xi32>
    %133 = llvm.bitcast %131 : i32 to f32
    %134 = llvm.bitcast %132 : i32 to f32
    %135 = nvvm.cvt.packfloat.f32 %134, %133, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %136 = llvm.shl %130, %16 : i32
    %137 = llvm.or %136, %135 : i32
    %138 = llvm.extractelement %124[%9 : i64] : vector<8xi32>
    %139 = llvm.extractelement %124[%10 : i64] : vector<8xi32>
    %140 = llvm.bitcast %138 : i32 to f32
    %141 = llvm.bitcast %139 : i32 to f32
    %142 = nvvm.cvt.packfloat.f32 %141, %140, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %143 = llvm.shl %137, %16 : i32
    %144 = llvm.or %143, %142 : i32
    %145 = llvm.extractelement %124[%1 : i64] : vector<8xi32>
    %146 = llvm.extractelement %124[%0 : i64] : vector<8xi32>
    %147 = llvm.bitcast %145 : i32 to f32
    %148 = llvm.bitcast %146 : i32 to f32
    %149 = nvvm.cvt.packfloat.f32 %148, %147, %8 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %150 = llvm.shl %144, %16 : i32
    %151 = llvm.or %150, %149 : i32
    %152 = llvm.insertelement %151, %2[%1 : i64] : vector<1xi32>
    %153 = llvm.bitcast %152 : vector<1xi32> to vector<4xi8>
    llvm.store %153, %19 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    %154 = llvm.getelementptr %19[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %155 = llvm.getelementptr %84[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %156 = llvm.getelementptr %19[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %157 = llvm.getelementptr %84[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %158 = llvm.getelementptr %19[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %159 = llvm.getelementptr %84[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    llvm.br ^bb5(%8 : i32)
  ^bb5(%160: i32):  // 2 preds: ^bb4, ^bb6
    %161 = llvm.icmp "slt" %160, %18 : i32
    llvm.cond_br %161, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %162 = llvm.load %19 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %162, %84 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %163 = llvm.load %154 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %163, %155 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %164 = llvm.load %156 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %164, %157 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %165 = llvm.load %158 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %165, %159 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %166 = llvm.add %160, %18 : i32
    llvm.br ^bb5(%166 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
