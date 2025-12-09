gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
    %35 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %36 = llvm.extractvalue %35[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %37 = llvm.extractvalue %36[0] : !llvm.struct<(i32, i32, i32)> 
    %38 = llvm.extractvalue %36[1] : !llvm.struct<(i32, i32, i32)> 
    %39 = llvm.extractvalue %35[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %40 = llvm.extractvalue %39[0] : !llvm.struct<(i64, i64)> 
    %41 = llvm.extractvalue %39[1] : !llvm.struct<(i64, i64)> 
    %42 = llvm.sdiv %13, %37 : i32
    %43 = llvm.srem %13, %37 : i32
    %44 = llvm.sext %43 : i32 to i64
    %45 = llvm.mul %44, %40 : i64
    %46 = llvm.sdiv %42, %38 : i32
    %47 = llvm.srem %42, %38 : i32
    %48 = llvm.mul %47, %6 : i32
    %49 = llvm.sext %48 : i32 to i64
    %50 = llvm.add %45, %49 : i64
    %51 = llvm.sext %46 : i32 to i64
    %52 = llvm.mul %51, %41 : i64
    %53 = llvm.add %50, %52 : i64
    %54 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %55 = llvm.getelementptr %54[%53] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
    %56 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %57 = llvm.extractvalue %56[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %58 = llvm.extractvalue %57[0] : !llvm.struct<(i32, i32, i32)> 
    %59 = llvm.extractvalue %57[1] : !llvm.struct<(i32, i32, i32)> 
    %60 = llvm.sdiv %13, %58 : i32
    %61 = llvm.srem %13, %58 : i32
    %62 = llvm.sdiv %60, %59 : i32
    %63 = llvm.srem %60, %59 : i32
    %64 = llvm.mul %63, %6 : i32
    %65 = llvm.mul %12, %8 : i32
    %66 = llvm.getelementptr %34[%65] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %67 = llvm.getelementptr %55[%65] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
    %68 = llvm.add %64, %65 : i32
    %69 = llvm.icmp "slt" %61, %arg3 : i32
    %70 = llvm.icmp "slt" %68, %arg4 : i32
    %71 = llvm.and %69, %70 : i1
    %72 = llvm.icmp "slt" %62, %arg5 : i32
    %73 = llvm.and %71, %72 : i1
    llvm.cond_br %73, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %74 = llvm.getelementptr %66[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %75 = llvm.getelementptr %11[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %76 = llvm.getelementptr %66[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %77 = llvm.getelementptr %11[2] : (!llvm.ptr) -> !llvm.ptr, f32
    %78 = llvm.getelementptr %66[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
    %79 = llvm.getelementptr %11[3] : (!llvm.ptr) -> !llvm.ptr, f32
    llvm.br ^bb2(%7 : i32)
  ^bb2(%80: i32):  // 2 preds: ^bb1, ^bb3
    %81 = llvm.icmp "slt" %80, %9 : i32
    llvm.cond_br %81, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %82 = llvm.load %66 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %82, %11 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %83 = llvm.load %74 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %83, %75 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %84 = llvm.load %76 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %84, %77 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %85 = llvm.load %78 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
    llvm.store %85, %79 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
    %86 = llvm.add %80, %9 : i32
    llvm.br ^bb2(%86 : i32)
  ^bb4:  // pred: ^bb2
    %87 = llvm.load %11 {alignment = 32 : i64} : !llvm.ptr -> vector<4xf32>
    %88 = llvm.bitcast %87 : vector<4xf32> to vector<4xi32>
    %89 = llvm.extractelement %88[%2 : i64] : vector<4xi32>
    %90 = llvm.extractelement %88[%1 : i64] : vector<4xi32>
    %91 = llvm.bitcast %89 : i32 to f32
    %92 = llvm.bitcast %90 : i32 to f32
    %93 = nvvm.cvt.packfloat.f32 %92, %91, %7 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %94 = llvm.or %7, %93 : i32
    %95 = llvm.extractelement %88[%3 : i64] : vector<4xi32>
    %96 = llvm.extractelement %88[%0 : i64] : vector<4xi32>
    %97 = llvm.bitcast %95 : i32 to f32
    %98 = llvm.bitcast %96 : i32 to f32
    %99 = nvvm.cvt.packfloat.f32 %98, %97, %7 {rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}
    %100 = llvm.shl %94, %4 : i32
    %101 = llvm.or %100, %99 : i32
    %102 = llvm.insertelement %101, %5[%3 : i64] : vector<1xi32>
    %103 = llvm.bitcast %102 : vector<1xi32> to vector<4xi8>
    llvm.store %103, %10 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
    %104 = llvm.getelementptr %10[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %105 = llvm.getelementptr %67[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %106 = llvm.getelementptr %10[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %107 = llvm.getelementptr %67[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    %108 = llvm.getelementptr %10[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %109 = llvm.getelementptr %67[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
    llvm.br ^bb5(%7 : i32)
  ^bb5(%110: i32):  // 2 preds: ^bb4, ^bb6
    %111 = llvm.icmp "slt" %110, %9 : i32
    llvm.cond_br %111, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %112 = llvm.load %10 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %112, %67 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %113 = llvm.load %104 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %113, %105 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %114 = llvm.load %106 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %114, %107 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %115 = llvm.load %108 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
    llvm.store %115, %109 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
    %116 = llvm.add %110, %9 : i32
    llvm.br ^bb5(%116 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
