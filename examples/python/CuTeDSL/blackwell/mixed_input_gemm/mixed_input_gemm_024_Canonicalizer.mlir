#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %65 = llvm.mul %8, %3 : i32
      %66 = llvm.add %58, %65 : i32
      %67 = llvm.icmp "slt" %66, %arg3 : i32
      %68 = llvm.icmp "slt" %60, %arg4 : i32
      %69 = llvm.and %67, %68 : i1
      %70 = llvm.icmp "slt" %59, %arg5 : i32
      %71 = llvm.and %69, %70 : i1
      llvm.cond_br %71, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %72 = llvm.getelementptr %62[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %73 = llvm.getelementptr %7[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %74 = llvm.getelementptr %62[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %75 = llvm.getelementptr %7[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %76 = llvm.getelementptr %62[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %77 = llvm.getelementptr %7[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %78 = llvm.getelementptr %62[4] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %79 = llvm.getelementptr %7[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %80 = llvm.getelementptr %62[5] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %81 = llvm.getelementptr %7[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %82 = llvm.getelementptr %62[6] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %83 = llvm.getelementptr %7[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %84 = llvm.getelementptr %62[7] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %85 = llvm.getelementptr %7[7] : (!llvm.ptr) -> !llvm.ptr, f32
      llvm.br ^bb2(%2 : i32)
    ^bb2(%86: i32):  // 2 preds: ^bb1, ^bb3
      %87 = llvm.icmp "slt" %86, %5 : i32
      llvm.cond_br %87, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %88 = llvm.load %62 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %88, %7 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %89 = llvm.load %72 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %89, %73 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %90 = llvm.load %74 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %90, %75 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %91 = llvm.load %76 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %91, %77 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %92 = llvm.load %78 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %92, %79 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %93 = llvm.load %80 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %93, %81 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %94 = llvm.load %82 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %94, %83 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %95 = llvm.load %84 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %95, %85 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %96 = llvm.add %86, %5 : i32
      llvm.br ^bb2(%96 : i32)
    ^bb4:  // pred: ^bb2
      %97 = llvm.load %7 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
      %98 = llvm.fptosi %97 : vector<8xf32> to vector<8xi4>
      %99 = vector.bitcast %98 : vector<8xi4> to vector<4xi8>
      llvm.store %99, %6 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
      %100 = llvm.getelementptr %6[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %101 = llvm.getelementptr %64[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
      %102 = llvm.getelementptr %6[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %103 = llvm.getelementptr %64[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
      %104 = llvm.getelementptr %6[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %105 = llvm.getelementptr %64[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, i8
      llvm.br ^bb5(%2 : i32)
    ^bb5(%106: i32):  // 2 preds: ^bb4, ^bb6
      %107 = llvm.icmp "slt" %106, %5 : i32
      llvm.cond_br %107, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %108 = llvm.load %6 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %108, %64 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %109 = llvm.load %100 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %109, %101 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %110 = llvm.load %102 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %110, %103 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %111 = llvm.load %104 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %111, %105 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %112 = llvm.add %106, %5 : i32
      llvm.br ^bb5(%112 : i32)
    ^bb7:  // pred: ^bb5
      llvm.br ^bb8
    ^bb8:  // 2 preds: ^bb0, ^bb7
      llvm.return
    }
  }
  llvm.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>
    %1 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %2 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %3 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %4 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %5 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %6 = llvm.mlir.constant(2 : i64) : i64
    %7 = llvm.mlir.constant(false) : i1
    %8 = llvm.mlir.constant(true) : i1
    %9 = llvm.mlir.constant(-1 : i32) : i32
    %10 = llvm.mlir.constant(2 : i32) : i32
    %11 = llvm.mlir.constant(1 : i32) : i32
    %12 = llvm.mlir.constant(128 : i32) : i32
    %13 = llvm.mlir.constant(0 : i64) : i64
    %14 = llvm.mlir.constant(0 : i32) : i32
    %15 = llvm.mlir.constant(512 : i32) : i32
    %16 = llvm.mlir.poison : !llvm.struct<()>
    %17 = llvm.mlir.constant(1024 : i32) : i32
    %18 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %19 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %20 = llvm.extractvalue %19[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %21 = llvm.extractvalue %19[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %22 = llvm.extractvalue %19[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %23 = llvm.extractvalue %19[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %24 = llvm.extractvalue %19[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %25 = llvm.select %8, %9, %11 : i1, i32
    %26 = llvm.add %25, %20 : i32
    %27 = llvm.sdiv %26, %10 : i32
    %28 = llvm.add %27, %11 : i32
    %29 = llvm.sub %14, %20 : i32
    %30 = llvm.sdiv %29, %10 : i32
    %31 = llvm.sub %14, %30 : i32
    %32 = llvm.icmp "slt" %20, %14 : i32
    %33 = llvm.icmp "sgt" %20, %14 : i32
    %34 = llvm.and %32, %7 : i1
    %35 = llvm.and %33, %8 : i1
    %36 = llvm.or %34, %35 : i1
    %37 = llvm.select %36, %28, %31 : i1, i32
    %38 = llvm.sdiv %23, %6 : i64
    %39 = llvm.icmp "ne" %38, %13 : i64
    llvm.cond_br %39, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    llvm.br ^bb11(%38 : i64)
  ^bb2:  // pred: ^bb0
    %40 = llvm.icmp "sgt" %23, %13 : i64
    llvm.cond_br %40, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    llvm.br ^bb9(%11 : i32)
  ^bb4:  // pred: ^bb2
    %41 = llvm.icmp "eq" %23, %13 : i64
    llvm.cond_br %41, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    llvm.br ^bb7(%14 : i32)
  ^bb6:  // pred: ^bb4
    llvm.br ^bb7(%9 : i32)
  ^bb7(%42: i32):  // 2 preds: ^bb5, ^bb6
    llvm.br ^bb8
  ^bb8:  // pred: ^bb7
    llvm.br ^bb9(%42 : i32)
  ^bb9(%43: i32):  // 2 preds: ^bb3, ^bb8
    llvm.br ^bb10
  ^bb10:  // pred: ^bb9
    %44 = llvm.sext %43 : i32 to i64
    llvm.br ^bb11(%44 : i64)
  ^bb11(%45: i64):  // 2 preds: ^bb1, ^bb10
    llvm.br ^bb12
  ^bb12:  // pred: ^bb11
    %46 = llvm.sdiv %24, %6 : i64
    %47 = llvm.icmp "ne" %46, %13 : i64
    llvm.cond_br %47, ^bb13, ^bb14
  ^bb13:  // pred: ^bb12
    llvm.br ^bb23(%46 : i64)
  ^bb14:  // pred: ^bb12
    %48 = llvm.icmp "sgt" %24, %13 : i64
    llvm.cond_br %48, ^bb15, ^bb16
  ^bb15:  // pred: ^bb14
    llvm.br ^bb21(%11 : i32)
  ^bb16:  // pred: ^bb14
    %49 = llvm.icmp "eq" %24, %13 : i64
    llvm.cond_br %49, ^bb17, ^bb18
  ^bb17:  // pred: ^bb16
    llvm.br ^bb19(%14 : i32)
  ^bb18:  // pred: ^bb16
    llvm.br ^bb19(%9 : i32)
  ^bb19(%50: i32):  // 2 preds: ^bb17, ^bb18
    llvm.br ^bb20
  ^bb20:  // pred: ^bb19
    llvm.br ^bb21(%50 : i32)
  ^bb21(%51: i32):  // 2 preds: ^bb15, ^bb20
    llvm.br ^bb22
  ^bb22:  // pred: ^bb21
    %52 = llvm.sext %51 : i32 to i64
    llvm.br ^bb23(%52 : i64)
  ^bb23(%53: i64):  // 2 preds: ^bb13, ^bb22
    llvm.br ^bb24
  ^bb24:  // pred: ^bb23
    %54 = llvm.insertvalue %37, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %55 = llvm.insertvalue %21, %54[1] : !llvm.struct<(i32, i32, i32)> 
    %56 = llvm.insertvalue %22, %55[2] : !llvm.struct<(i32, i32, i32)> 
    %57 = llvm.insertvalue %45, %4[0] : !llvm.struct<(i64, i64)> 
    %58 = llvm.insertvalue %53, %57[1] : !llvm.struct<(i64, i64)> 
    %59 = llvm.insertvalue %56, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %60 = llvm.insertvalue %58, %59[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %61 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %62 = llvm.extractvalue %61[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %63 = llvm.extractvalue %62[0] : !llvm.struct<(i32, i32, i32)> 
    %64 = llvm.extractvalue %62[1] : !llvm.struct<(i32, i32, i32)> 
    %65 = llvm.extractvalue %62[2] : !llvm.struct<(i32, i32, i32)> 
    %66 = llvm.insertvalue %63, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %67 = llvm.insertvalue %64, %66[1] : !llvm.struct<(i32, i32, i32)> 
    %68 = llvm.insertvalue %65, %67[2] : !llvm.struct<(i32, i32, i32)> 
    %69 = llvm.insertvalue %68, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %70 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %71 = llvm.extractvalue %61[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %72 = llvm.extractvalue %61[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %73 = llvm.extractvalue %61[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %74 = llvm.extractvalue %61[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %75 = llvm.extractvalue %61[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %76 = llvm.select %8, %9, %11 : i1, i32
    %77 = llvm.add %76, %71 : i32
    %78 = llvm.sdiv %77, %17 : i32
    %79 = llvm.add %78, %11 : i32
    %80 = llvm.sub %14, %71 : i32
    %81 = llvm.sdiv %80, %17 : i32
    %82 = llvm.sub %14, %81 : i32
    %83 = llvm.icmp "slt" %71, %14 : i32
    %84 = llvm.icmp "sgt" %71, %14 : i32
    %85 = llvm.and %83, %7 : i1
    %86 = llvm.and %84, %8 : i1
    %87 = llvm.or %85, %86 : i1
    %88 = llvm.select %87, %79, %82 : i1, i32
    %89 = llvm.insertvalue %88, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %90 = llvm.insertvalue %72, %89[1] : !llvm.struct<(i32, i32, i32)> 
    %91 = llvm.insertvalue %73, %90[2] : !llvm.struct<(i32, i32, i32)> 
    %92 = llvm.insertvalue %74, %4[0] : !llvm.struct<(i64, i64)> 
    %93 = llvm.insertvalue %75, %92[1] : !llvm.struct<(i64, i64)> 
    %94 = llvm.insertvalue %91, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %95 = llvm.insertvalue %93, %94[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %96 = llvm.insertvalue %70, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %97 = llvm.insertvalue %95, %96[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %98 = llvm.extractvalue %69[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %99 = llvm.extractvalue %69[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %100 = llvm.extractvalue %69[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %101 = llvm.select %8, %9, %11 : i1, i32
    %102 = llvm.add %101, %98 : i32
    %103 = llvm.sdiv %102, %17 : i32
    %104 = llvm.add %103, %11 : i32
    %105 = llvm.sub %14, %98 : i32
    %106 = llvm.sdiv %105, %17 : i32
    %107 = llvm.sub %14, %106 : i32
    %108 = llvm.icmp "slt" %98, %14 : i32
    %109 = llvm.icmp "sgt" %98, %14 : i32
    %110 = llvm.and %108, %7 : i1
    %111 = llvm.and %109, %8 : i1
    %112 = llvm.or %110, %111 : i1
    %113 = llvm.select %112, %104, %107 : i1, i32
    %114 = llvm.insertvalue %113, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %115 = llvm.insertvalue %99, %114[1] : !llvm.struct<(i32, i32, i32)> 
    %116 = llvm.insertvalue %100, %115[2] : !llvm.struct<(i32, i32, i32)> 
    %117 = llvm.insertvalue %116, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %118 = llvm.insertvalue %16, %117[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %119 = llvm.insertvalue %16, %0[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %120 = llvm.insertvalue %118, %119[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %121 = llvm.extractvalue %59[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %122 = llvm.extractvalue %59[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %123 = llvm.extractvalue %59[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %124 = llvm.extractvalue %60[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %125 = llvm.extractvalue %60[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %126 = llvm.select %8, %9, %11 : i1, i32
    %127 = llvm.add %126, %121 : i32
    %128 = llvm.sdiv %127, %15 : i32
    %129 = llvm.add %128, %11 : i32
    %130 = llvm.sub %14, %121 : i32
    %131 = llvm.sdiv %130, %15 : i32
    %132 = llvm.sub %14, %131 : i32
    %133 = llvm.icmp "slt" %121, %14 : i32
    %134 = llvm.icmp "sgt" %121, %14 : i32
    %135 = llvm.and %133, %7 : i1
    %136 = llvm.and %134, %8 : i1
    %137 = llvm.or %135, %136 : i1
    %138 = llvm.select %137, %129, %132 : i1, i32
    %139 = llvm.insertvalue %138, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %140 = llvm.insertvalue %122, %139[1] : !llvm.struct<(i32, i32, i32)> 
    %141 = llvm.insertvalue %123, %140[2] : !llvm.struct<(i32, i32, i32)> 
    %142 = llvm.insertvalue %124, %4[0] : !llvm.struct<(i64, i64)> 
    %143 = llvm.insertvalue %125, %142[1] : !llvm.struct<(i64, i64)> 
    %144 = llvm.insertvalue %141, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %145 = llvm.insertvalue %143, %144[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %146 = llvm.insertvalue %18, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %147 = llvm.insertvalue %145, %146[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %148 = llvm.mul %88, %72 : i32
    %149 = llvm.mul %148, %73 : i32
    %150 = llvm.inttoptr %13 : i64 to !llvm.ptr
    %151 = llvm.alloca %11 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %152 = llvm.alloca %11 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %153 = llvm.getelementptr %151[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %152, %153 : !llvm.ptr, !llvm.ptr
    %154 = llvm.getelementptr %151[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %12, %154 : i32, !llvm.ptr
    %155 = llvm.getelementptr %151[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %11, %155 : i32, !llvm.ptr
    %156 = llvm.getelementptr %151[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %11, %156 : i32, !llvm.ptr
    %157 = llvm.getelementptr %151[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %13, %157 : i64, !llvm.ptr
    %158 = llvm.getelementptr %151[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %149, %158 : i32, !llvm.ptr
    %159 = llvm.getelementptr %151[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %11, %159 : i32, !llvm.ptr
    %160 = llvm.getelementptr %151[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %11, %160 : i32, !llvm.ptr
    %161 = llvm.getelementptr %151[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %14, %161 : i32, !llvm.ptr
    %162 = llvm.getelementptr %151[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %150, %162 : !llvm.ptr, !llvm.ptr
    %163 = llvm.alloca %11 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %164 = llvm.getelementptr %163[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %151, %164 : !llvm.ptr, !llvm.ptr
    %165 = builtin.unrealized_conversion_cast %163 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %166 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0<%165> (%97, %147, %120, %63, %64, %65) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, i32, i32, i32) -> !cuda.result
    %167 = builtin.unrealized_conversion_cast %166 : !cuda.result to i32
    cuda.return_if_error %167 : i32
    llvm.return %14 : i32
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> i32
    llvm.return %0 : i32
  }
}
