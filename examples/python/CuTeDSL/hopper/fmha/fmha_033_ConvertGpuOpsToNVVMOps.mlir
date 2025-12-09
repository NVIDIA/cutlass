gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} {
  llvm.func @kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000i64div2561_tensor00000o1256111011000102561121314______Float16_Float32_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(i64, i64)>)>
    %1 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %2 = llvm.mlir.constant(256 : i32) : i32
    %3 = llvm.mlir.constant(2 : i64) : i64
    %4 = llvm.mlir.constant(0 : i32) : i32
    %5 = llvm.mlir.poison : !llvm.struct<()>
    %6 = llvm.mlir.constant(2 : i32) : i32
    %7 = llvm.mlir.constant(1 : i32) : i32
    %8 = llvm.alloca %6 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %9 = llvm.alloca %6 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %10 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %11 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %12 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64)>)>)> 
    %13 = llvm.extractvalue %12[0] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64)>)> 
    %14 = llvm.extractvalue %13[0] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %15 = llvm.extractvalue %13[1] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %16 = llvm.extractvalue %13[2] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %17 = llvm.extractvalue %13[3] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %18 = llvm.extractvalue %12[1] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64)>)> 
    %19 = llvm.extractvalue %18[0] : !llvm.struct<(i64, i64, i64, i64)> 
    %20 = llvm.extractvalue %18[1] : !llvm.struct<(i64, i64, i64, i64)> 
    %21 = llvm.extractvalue %18[2] : !llvm.struct<(i64, i64, i64, i64)> 
    %22 = llvm.extractvalue %18[3] : !llvm.struct<(i64, i64, i64, i64)> 
    %23 = llvm.sdiv %11, %14 : i32
    %24 = llvm.srem %11, %14 : i32
    %25 = llvm.sext %24 : i32 to i64
    %26 = llvm.mul %25, %19 : i64
    %27 = llvm.sdiv %23, %15 : i32
    %28 = llvm.srem %23, %15 : i32
    %29 = llvm.mul %28, %2 : i32
    %30 = llvm.sext %29 : i32 to i64
    %31 = llvm.add %26, %30 : i64
    %32 = llvm.sdiv %27, %16 : i32
    %33 = llvm.srem %27, %16 : i32
    %34 = llvm.sext %33 : i32 to i64
    %35 = llvm.mul %34, %20 : i64
    %36 = llvm.add %31, %35 : i64
    %37 = llvm.sdiv %32, %17 : i32
    %38 = llvm.srem %32, %17 : i32
    %39 = llvm.sext %38 : i32 to i64
    %40 = llvm.mul %39, %21 : i64
    %41 = llvm.add %36, %40 : i64
    %42 = llvm.sext %37 : i32 to i64
    %43 = llvm.mul %42, %22 : i64
    %44 = llvm.add %41, %43 : i64
    %45 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64)>)>)> 
    %46 = llvm.getelementptr %45[%44] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
    %47 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)>)> 
    %48 = llvm.extractvalue %47[1, 0] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)> 
    %49 = llvm.extractvalue %47[0] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)> 
    %50 = llvm.extractvalue %49[0] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %51 = llvm.extractvalue %49[1] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %52 = llvm.extractvalue %49[2] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %53 = llvm.extractvalue %49[3] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %54 = llvm.extractvalue %47[1] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)> 
    %55 = llvm.extractvalue %54[1] : !llvm.struct<(i64, i64, i64, i64, i64)> 
    %56 = llvm.extractvalue %54[2] : !llvm.struct<(i64, i64, i64, i64, i64)> 
    %57 = llvm.extractvalue %54[3] : !llvm.struct<(i64, i64, i64, i64, i64)> 
    %58 = llvm.extractvalue %54[4] : !llvm.struct<(i64, i64, i64, i64, i64)> 
    %59 = llvm.sdiv %11, %50 : i32
    %60 = llvm.srem %11, %50 : i32
    %61 = llvm.sext %60 : i32 to i64
    %62 = llvm.mul %61, %55 : i64
    %63 = llvm.sdiv %59, %51 : i32
    %64 = llvm.srem %59, %51 : i32
    %65 = llvm.sext %64 : i32 to i64
    %66 = llvm.mul %65, %56 : i64
    %67 = llvm.add %62, %66 : i64
    %68 = llvm.sdiv %63, %52 : i32
    %69 = llvm.srem %63, %52 : i32
    %70 = llvm.sext %69 : i32 to i64
    %71 = llvm.mul %70, %57 : i64
    %72 = llvm.add %67, %71 : i64
    %73 = llvm.sdiv %68, %53 : i32
    %74 = llvm.srem %68, %53 : i32
    %75 = llvm.sext %74 : i32 to i64
    %76 = llvm.add %72, %75 : i64
    %77 = llvm.sext %73 : i32 to i64
    %78 = llvm.mul %77, %58 : i64
    %79 = llvm.add %76, %78 : i64
    %80 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<(i64, i64, i64, i64, i64)>)>)> 
    %81 = llvm.getelementptr %80[%79] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %82 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32, i32, i32)>, struct<()>)>)> 
    %83 = llvm.extractvalue %82[0] : !llvm.struct<(struct<(i32, i32, i32, i32, i32)>, struct<()>)> 
    %84 = llvm.extractvalue %83[0] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %85 = llvm.extractvalue %83[1] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %86 = llvm.extractvalue %83[2] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %87 = llvm.extractvalue %83[3] : !llvm.struct<(i32, i32, i32, i32, i32)> 
    %88 = llvm.sdiv %11, %84 : i32
    %89 = llvm.srem %11, %84 : i32
    %90 = llvm.sdiv %88, %85 : i32
    %91 = llvm.srem %88, %85 : i32
    %92 = llvm.mul %91, %2 : i32
    %93 = llvm.sdiv %90, %86 : i32
    %94 = llvm.srem %90, %86 : i32
    %95 = llvm.sdiv %93, %87 : i32
    %96 = llvm.srem %93, %87 : i32
    %97 = llvm.mul %48, %3 : i64
    %98 = llvm.insertvalue %97, %1[0] : !llvm.struct<(i64, i64)> 
    %99 = llvm.insertvalue %48, %98[1] : !llvm.struct<(i64, i64)> 
    %100 = llvm.insertvalue %5, %0[0] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %101 = llvm.insertvalue %99, %100[1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %102 = llvm.mul %10, %6 : i32
    %103 = llvm.getelementptr %46[%102] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
    %104 = llvm.extractvalue %101[1, 1] : !llvm.struct<(struct<()>, struct<(i64, i64)>)> 
    %105 = llvm.sext %10 : i32 to i64
    %106 = llvm.mul %105, %97 : i64
    %107 = llvm.getelementptr %81[%106] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    %108 = llvm.add %92, %102 : i32
    %109 = llvm.icmp "slt" %89, %arg3 : i32
    %110 = llvm.icmp "slt" %108, %arg4 : i32
    %111 = llvm.and %109, %110 : i1
    %112 = llvm.icmp "slt" %94, %arg5 : i32
    %113 = llvm.and %111, %112 : i1
    %114 = llvm.icmp "slt" %96, %arg6 : i32
    %115 = llvm.and %113, %114 : i1
    %116 = llvm.icmp "slt" %95, %arg7 : i32
    %117 = llvm.and %115, %116 : i1
    llvm.cond_br %117, ^bb1, ^bb8
  ^bb1:  // pred: ^bb0
    %118 = llvm.getelementptr %103[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f16
    %119 = llvm.getelementptr %9[1] : (!llvm.ptr) -> !llvm.ptr, f16
    llvm.br ^bb2(%4 : i32)
  ^bb2(%120: i32):  // 2 preds: ^bb1, ^bb3
    %121 = llvm.icmp "slt" %120, %7 : i32
    llvm.cond_br %121, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %122 = llvm.load %103 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
    llvm.store %122, %9 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
    %123 = llvm.load %118 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
    llvm.store %123, %119 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
    %124 = llvm.add %120, %7 : i32
    llvm.br ^bb2(%124 : i32)
  ^bb4:  // pred: ^bb2
    %125 = llvm.load %9 {alignment = 32 : i64} : !llvm.ptr -> vector<2xf16>
    %126 = llvm.fpext %125 : vector<2xf16> to vector<2xf32>
    llvm.store %126, %8 {alignment = 32 : i64} : vector<2xf32>, !llvm.ptr
    %127 = llvm.getelementptr %8[1] : (!llvm.ptr) -> !llvm.ptr, f32
    %128 = llvm.getelementptr %107[%104] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
    llvm.br ^bb5(%4 : i32)
  ^bb5(%129: i32):  // 2 preds: ^bb4, ^bb6
    %130 = llvm.icmp "slt" %129, %7 : i32
    llvm.cond_br %130, ^bb6, ^bb7 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb6:  // pred: ^bb5
    %131 = llvm.load %8 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
    llvm.store %131, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
    %132 = llvm.load %127 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
    llvm.store %132, %128 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
    %133 = llvm.add %129, %7 : i32
    llvm.br ^bb5(%133 : i32)
  ^bb7:  // pred: ^bb5
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb0, ^bb7
    llvm.return
  }
}
