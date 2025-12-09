gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1102410101024_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.mlir.constant(3 : i64) : i64
    %2 = llvm.mlir.constant(2 : i64) : i64
    %3 = llvm.mlir.constant(5 : i64) : i64
    %4 = llvm.mlir.constant(4 : i64) : i64
    %5 = llvm.mlir.constant(7 : i64) : i64
    %6 = llvm.mlir.constant(6 : i64) : i64
    %7 = llvm.mlir.constant(0 : i64) : i64
    %8 = llvm.mlir.undef : vector<1xi32>
    %9 = llvm.mlir.constant(512 : i32) : i32
    %10 = llvm.mlir.constant(1024 : i32) : i32
    %11 = llvm.mlir.constant(0 : i32) : i32
    %12 = llvm.mlir.constant(8 : i32) : i32
    %13 = llvm.mlir.constant(4 : i32) : i32
    %14 = llvm.mlir.constant(1 : i32) : i32
    %15 = llvm.alloca %13 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %16 = llvm.alloca %12 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %17 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %18 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %19 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %20 = llvm.extractvalue %19[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %21 = llvm.extractvalue %20[0] : !llvm.struct<(i32, i32, i32)> 
    %22 = llvm.extractvalue %20[1] : !llvm.struct<(i32, i32, i32)> 
    %23 = llvm.extractvalue %19[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %24 = llvm.extractvalue %23[0] : !llvm.struct<(i64, i64)> 
    %25 = llvm.extractvalue %23[1] : !llvm.struct<(i64, i64)> 
    %26 = llvm.sdiv %18, %21 : i32
    %27 = llvm.srem %18, %21 : i32
    %28 = llvm.sext %27 : i32 to i64
    %29 = llvm.mul %28, %24 : i64
    %30 = llvm.sdiv %26, %22 : i32
    %31 = llvm.srem %26, %22 : i32
    %32 = llvm.mul %31, %10 : i32
    %33 = llvm.sext %32 : i32 to i64
    %34 = llvm.add %29, %33 : i64
    %35 = llvm.sext %30 : i32 to i64
    %36 = llvm.mul %35, %25 : i64
    %37 = llvm.add %34, %36 : i64
    %38 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %39 = llvm.getelementptr %38[%37] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %40 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %41 = llvm.extractvalue %40[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %42 = llvm.extractvalue %41[0] : !llvm.struct<(i32, i32, i32)> 
    %43 = llvm.extractvalue %41[1] : !llvm.struct<(i32, i32, i32)> 
    %44 = llvm.extractvalue %40[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %45 = llvm.extractvalue %44[0] : !llvm.struct<(i64, i64)> 
    %46 = llvm.extractvalue %44[1] : !llvm.struct<(i64, i64)> 
    %47 = llvm.sdiv %18, %42 : i32
    %48 = llvm.srem %18, %42 : i32
    %49 = llvm.sext %48 : i32 to i64
    %50 = llvm.mul %49, %45 : i64
    %51 = llvm.sdiv %47, %43 : i32
    %52 = llvm.srem %47, %43 : i32
    %53 = llvm.mul %52, %9 : i32
    %54 = llvm.sext %53 : i32 to i64
    %55 = llvm.add %50, %54 : i64
    %56 = llvm.sext %51 : i32 to i64
    %57 = llvm.mul %56, %46 : i64
    %58 = llvm.add %55, %57 : i64
    %59 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %60 = llvm.getelementptr %59[%58] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %61 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %62 = llvm.extractvalue %61[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %63 = llvm.extractvalue %62[0] : !llvm.struct<(i32, i32, i32)> 
    %64 = llvm.extractvalue %62[1] : !llvm.struct<(i32, i32, i32)> 
    %65 = llvm.sdiv %18, %63 : i32
    %66 = llvm.srem %18, %63 : i32
    %67 = llvm.sdiv %65, %64 : i32
    %68 = llvm.srem %65, %64 : i32
    %69 = llvm.mul %68, %10 : i32
    %70 = llvm.mul %17, %12 : i32
    %71 = llvm.getelementptr %39[%70] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %72 = llvm.mul %17, %13 : i32
    %73 = llvm.getelementptr %60[%72] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %74 = llvm.add %69, %70 : i32
    %75 = llvm.icmp "slt" %66, %arg3 : i32
    %76 = llvm.icmp "slt" %74, %arg4 : i32
    %77 = llvm.and %75, %76 : i1
    %78 = llvm.icmp "slt" %67, %arg5 : i32
    %79 = llvm.and %77, %78 : i1
    llvm.cond_br %79, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %80 = llvm.getelementptr %71[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %81 = llvm.getelementptr %16[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %82 = llvm.getelementptr %71[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %83 = llvm.getelementptr %16[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %84 = llvm.getelementptr %71[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %85 = llvm.getelementptr %16[3] : (!llvm.ptr) -> !llvm.ptr, f32
    %86 = llvm.getelementptr %71[4] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %87 = llvm.getelementptr %16[4] : (!llvm.ptr) -> !llvm.ptr, f32
    %88 = llvm.getelementptr %71[5] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %89 = llvm.getelementptr %16[5] : (!llvm.ptr) -> !llvm.ptr, f32
    %90 = llvm.getelementptr %71[6] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %91 = llvm.getelementptr %16[6] : (!llvm.ptr) -> !llvm.ptr, f32
    %92 = llvm.getelementptr %71[7] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %93 = llvm.getelementptr %16[7] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%11 : i32)
  ^bb2(%94: i32):  // 2 preds: ^bb1, ^bb3
    %95 = llvm.icmp "slt" %94, %14 : i32
    llvm.cond_br %95, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %96 = llvm.load %71 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %96, %16 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %97 = llvm.load %80 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %97, %81 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %98 = llvm.load %82 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %98, %83 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %99 = llvm.load %84 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %99, %85 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %100 = llvm.load %86 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %100, %87 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %101 = llvm.load %88 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %101, %89 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %102 = llvm.load %90 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %102, %91 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %103 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %103, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %104 = llvm.add %94, %14 : i32
    llvm.br ^bb2(%104 : i32)
  ^bb4:  // pred: ^bb2
    %105 = llvm.load %16 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
    %106 = llvm.bitcast %105 : vector<8xf32> to vector<8xi32>
    %107 = llvm.extractelement %106[%6 : i64] : vector<8xi32>
    %108 = llvm.extractelement %106[%5 : i64] : vector<8xi32>
    %109 = llvm.bitcast %107 : i32 to f32
    %110 = llvm.bitcast %108 : i32 to f32
    %111 = nvvm.cvt.packfloat.f32 %110, %109, %11 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %112 = llvm.or %11, %111 : i32
    %113 = llvm.extractelement %106[%4 : i64] : vector<8xi32>
    %114 = llvm.extractelement %106[%3 : i64] : vector<8xi32>
    %115 = llvm.bitcast %113 : i32 to f32
    %116 = llvm.bitcast %114 : i32 to f32
    %117 = nvvm.cvt.packfloat.f32 %116, %115, %11 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %118 = llvm.shl %112, %12 : i32
    %119 = llvm.or %118, %117 : i32
    %120 = llvm.extractelement %106[%2 : i64] : vector<8xi32>
    %121 = llvm.extractelement %106[%1 : i64] : vector<8xi32>
    %122 = llvm.bitcast %120 : i32 to f32
    %123 = llvm.bitcast %121 : i32 to f32
    %124 = nvvm.cvt.packfloat.f32 %123, %122, %11 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %125 = llvm.shl %119, %12 : i32
    %126 = llvm.or %125, %124 : i32
    %127 = llvm.extractelement %106[%7 : i64] : vector<8xi32>
    %128 = llvm.extractelement %106[%0 : i64] : vector<8xi32>
    %129 = llvm.bitcast %127 : i32 to f32
    %130 = llvm.bitcast %128 : i32 to f32
    %131 = nvvm.cvt.packfloat.f32 %130, %129, %11 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}
    %132 = llvm.shl %126, %12 : i32
    %133 = llvm.or %132, %131 : i32
    %134 = llvm.insertelement %133, %8[%7 : i64] : vector<1xi32>
    %135 = llvm.bitcast %134 : vector<1xi32> to vector<8xi4>
    %136 = llvm.bitcast %135 : vector<8xi4> to vector<4xi8>
    llvm.store %136, %15 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    %137 = llvm.getelementptr %15[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %138 = llvm.getelementptr %73[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %139 = llvm.getelementptr %15[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %140 = llvm.getelementptr %73[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %141 = llvm.getelementptr %15[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %142 = llvm.getelementptr %73[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    llvm.br ^bb5(%11 : i32)
  ^bb5(%143: i32):  // 2 preds: ^bb4, ^bb6
    %144 = llvm.icmp "slt" %143, %14 : i32
    llvm.cond_br %144, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %145 = llvm.load %15 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %145, %73 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %146 = llvm.load %137 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %146, %138 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %147 = llvm.load %139 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %147, %140 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %148 = llvm.load %141 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %148, %142 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %149 = llvm.add %143, %14 : i32
    llvm.br ^bb5(%149 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
