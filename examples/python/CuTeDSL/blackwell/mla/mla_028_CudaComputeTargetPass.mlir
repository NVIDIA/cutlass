gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.mlir.constant(3 : i64) : i64
    %2 = llvm.mlir.constant(2 : i64) : i64
    %3 = llvm.mlir.constant(0 : i64) : i64
    %4 = llvm.mlir.constant(16 : i32) : i32
    %5 = llvm.mlir.undef : vector<1xi32>
    %6 = llvm.mlir.constant(512 : i32) : i32
    %7 = llvm.mlir.constant(0 : i32) : i32
    %8 = llvm.mlir.constant(4 : i32) : i32
    %9 = llvm.mlir.constant(1 : i32) : i32
    %10 = llvm.alloca %8 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %11 = llvm.alloca %8 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %12 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %13 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %14 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %15 = llvm.extractvalue %14[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %16 = llvm.extractvalue %15[0] : !llvm.struct<(i32, i32, i32)> 
    %17 = llvm.extractvalue %15[1] : !llvm.struct<(i32, i32, i32)> 
    %18 = llvm.extractvalue %14[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %19 = llvm.extractvalue %18[0] : !llvm.struct<(i64, i64)> 
    %20 = llvm.extractvalue %18[1] : !llvm.struct<(i64, i64)> 
    %21 = llvm.sdiv %13, %16 : i32
    %22 = llvm.srem %13, %16 : i32
    %23 = llvm.sext %22 : i32 to i64
    %24 = llvm.mul %23, %19 : i64
    %25 = llvm.sdiv %21, %17 : i32
    %26 = llvm.srem %21, %17 : i32
    %27 = llvm.mul %26, %6 : i32
    %28 = llvm.sext %27 : i32 to i64
    %29 = llvm.add %24, %28 : i64
    %30 = llvm.sext %25 : i32 to i64
    %31 = llvm.mul %30, %20 : i64
    %32 = llvm.add %29, %31 : i64
    %33 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %34 = llvm.getelementptr %33[%32] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %35 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)> 
    %36 = llvm.extractvalue %35[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)> 
    %37 = llvm.extractvalue %36[0] : !llvm.struct<(i32, i32, i32)> 
    %38 = llvm.extractvalue %36[1] : !llvm.struct<(i32, i32, i32)> 
    %39 = llvm.extractvalue %35[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)> 
    %40 = llvm.extractvalue %39[0] : !llvm.struct<(i32, i32)> 
    %41 = llvm.extractvalue %39[1] : !llvm.struct<(i32, i32)> 
    %42 = llvm.sdiv %13, %37 : i32
    %43 = llvm.srem %13, %37 : i32
    %44 = llvm.mul %43, %40 : i32
    %45 = llvm.sdiv %42, %38 : i32
    %46 = llvm.srem %42, %38 : i32
    %47 = llvm.mul %46, %6 : i32
    %48 = llvm.add %44, %47 : i32
    %49 = llvm.mul %45, %41 : i32
    %50 = llvm.add %48, %49 : i32
    %51 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>)> 
    %52 = llvm.getelementptr %51[%50] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %53 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %54 = llvm.extractvalue %53[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %55 = llvm.extractvalue %54[0] : !llvm.struct<(i32, i32, i32)> 
    %56 = llvm.extractvalue %54[1] : !llvm.struct<(i32, i32, i32)> 
    %57 = llvm.sdiv %13, %55 : i32
    %58 = llvm.srem %13, %55 : i32
    %59 = llvm.sdiv %57, %56 : i32
    %60 = llvm.srem %57, %56 : i32
    %61 = llvm.mul %60, %6 : i32
    %62 = llvm.mul %12, %8 : i32
    %63 = llvm.getelementptr %34[%62] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %64 = llvm.getelementptr %52[%62] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %65 = llvm.add %61, %62 : i32
    %66 = llvm.icmp "slt" %58, %arg3 : i32
    %67 = llvm.icmp "slt" %65, %arg4 : i32
    %68 = llvm.and %66, %67 : i1
    %69 = llvm.icmp "slt" %59, %arg5 : i32
    %70 = llvm.and %68, %69 : i1
    llvm.cond_br %70, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %71 = llvm.getelementptr %63[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %72 = llvm.getelementptr %11[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %73 = llvm.getelementptr %63[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %74 = llvm.getelementptr %11[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %75 = llvm.getelementptr %63[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %76 = llvm.getelementptr %11[3] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%7 : i32)
  ^bb2(%77: i32):  // 2 preds: ^bb1, ^bb3
    %78 = llvm.icmp "slt" %77, %9 : i32
    llvm.cond_br %78, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %79 = llvm.load %63 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %79, %11 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %80 = llvm.load %71 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %80, %72 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %81 = llvm.load %73 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %81, %74 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %82 = llvm.load %75 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %82, %76 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %83 = llvm.add %77, %9 : i32
    llvm.br ^bb2(%83 : i32)
  ^bb4:  // pred: ^bb2
    %84 = llvm.load %11 {alignment = 32 : i64} : !llvm.ptr -> vector<4xf32>
    %85 = llvm.bitcast %84 : vector<4xf32> to vector<4xi32>
    %86 = llvm.extractelement %85[%2 : i64] : vector<4xi32>
    %87 = llvm.extractelement %85[%1 : i64] : vector<4xi32>
    %88 = llvm.bitcast %86 : i32 to f32
    %89 = llvm.bitcast %87 : i32 to f32
    %90 = nvvm.cvt.packfloat.f32 %89, %88, %7 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %91 = llvm.or %7, %90 : i32
    %92 = llvm.extractelement %85[%3 : i64] : vector<4xi32>
    %93 = llvm.extractelement %85[%0 : i64] : vector<4xi32>
    %94 = llvm.bitcast %92 : i32 to f32
    %95 = llvm.bitcast %93 : i32 to f32
    %96 = nvvm.cvt.packfloat.f32 %95, %94, %7 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %97 = llvm.shl %91, %4 : i32
    %98 = llvm.or %97, %96 : i32
    %99 = llvm.insertelement %98, %5[%3 : i64] : vector<1xi32>
    %100 = llvm.bitcast %99 : vector<1xi32> to vector<4xi8>
    llvm.store %100, %10 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    llvm.br ^bb5(%7 : i32)
  ^bb5(%101: i32):  // 2 preds: ^bb4, ^bb6
    %102 = llvm.icmp "slt" %101, %9 : i32
    llvm.cond_br %102, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %103 = llvm.load %10 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
    llvm.store %103, %64 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
    %104 = llvm.add %101, %9 : i32
    llvm.br ^bb5(%104 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
