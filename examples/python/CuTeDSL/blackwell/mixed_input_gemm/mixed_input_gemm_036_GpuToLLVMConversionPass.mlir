#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
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
      llvm.cond_br %86, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
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
      llvm.cond_br %106, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
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
  llvm.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>
    %1 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %2 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %3 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %4 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %5 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %6 = llvm.mlir.constant(0 : i64) : i64
    %7 = llvm.mlir.constant(2 : i64) : i64
    %8 = llvm.mlir.constant(false) : i1
    %9 = llvm.mlir.constant(true) : i1
    %10 = llvm.mlir.constant(-1 : i32) : i32
    %11 = llvm.mlir.constant(1 : i32) : i32
    %12 = llvm.mlir.constant(2 : i32) : i32
    %13 = llvm.mlir.constant(1024 : i32) : i32
    %14 = llvm.mlir.poison : !llvm.struct<()>
    %15 = llvm.mlir.constant(512 : i32) : i32
    %16 = llvm.mlir.constant(1 : index) : i64
    %17 = llvm.mlir.constant(0 : i32) : i32
    %18 = llvm.mlir.constant(128 : index) : i64
    %19 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %20 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %21 = llvm.extractvalue %20[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %22 = llvm.extractvalue %20[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %23 = llvm.extractvalue %20[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %24 = llvm.extractvalue %20[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %25 = llvm.extractvalue %20[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %26 = llvm.select %9, %10, %11 : i1, i32
    %27 = llvm.add %26, %21 : i32
    %28 = llvm.sdiv %27, %12 : i32
    %29 = llvm.add %28, %11 : i32
    %30 = llvm.sub %17, %21 : i32
    %31 = llvm.sdiv %30, %12 : i32
    %32 = llvm.sub %17, %31 : i32
    %33 = llvm.icmp "slt" %21, %17 : i32
    %34 = llvm.icmp "sgt" %21, %17 : i32
    %35 = llvm.and %33, %8 : i1
    %36 = llvm.and %34, %9 : i1
    %37 = llvm.or %35, %36 : i1
    %38 = llvm.select %37, %29, %32 : i1, i32
    %39 = llvm.sdiv %24, %7 : i64
    %40 = llvm.icmp "ne" %39, %6 : i64
    llvm.cond_br %40, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    llvm.br ^bb9(%39 : i64)
  ^bb2:  // pred: ^bb0
    %41 = llvm.icmp "sgt" %24, %6 : i64
    llvm.cond_br %41, ^bb3(%11 : i32), ^bb4
  ^bb3(%42: i32):  // 2 preds: ^bb2, ^bb6
    llvm.br ^bb7
  ^bb4:  // pred: ^bb2
    %43 = llvm.icmp "eq" %24, %6 : i64
    llvm.cond_br %43, ^bb5(%17 : i32), ^bb5(%10 : i32)
  ^bb5(%44: i32):  // 2 preds: ^bb4, ^bb4
    llvm.br ^bb6
  ^bb6:  // pred: ^bb5
    llvm.br ^bb3(%44 : i32)
  ^bb7:  // pred: ^bb3
    llvm.br ^bb8
  ^bb8:  // pred: ^bb7
    %45 = llvm.sext %42 : i32 to i64
    llvm.br ^bb9(%45 : i64)
  ^bb9(%46: i64):  // 2 preds: ^bb1, ^bb8
    llvm.br ^bb10
  ^bb10:  // pred: ^bb9
    %47 = llvm.sdiv %25, %7 : i64
    %48 = llvm.icmp "ne" %47, %6 : i64
    llvm.cond_br %48, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    llvm.br ^bb19(%47 : i64)
  ^bb12:  // pred: ^bb10
    %49 = llvm.icmp "sgt" %25, %6 : i64
    llvm.cond_br %49, ^bb13(%11 : i32), ^bb14
  ^bb13(%50: i32):  // 2 preds: ^bb12, ^bb16
    llvm.br ^bb17
  ^bb14:  // pred: ^bb12
    %51 = llvm.icmp "eq" %25, %6 : i64
    llvm.cond_br %51, ^bb15(%17 : i32), ^bb15(%10 : i32)
  ^bb15(%52: i32):  // 2 preds: ^bb14, ^bb14
    llvm.br ^bb16
  ^bb16:  // pred: ^bb15
    llvm.br ^bb13(%52 : i32)
  ^bb17:  // pred: ^bb13
    llvm.br ^bb18
  ^bb18:  // pred: ^bb17
    %53 = llvm.sext %50 : i32 to i64
    llvm.br ^bb19(%53 : i64)
  ^bb19(%54: i64):  // 2 preds: ^bb11, ^bb18
    llvm.br ^bb20
  ^bb20:  // pred: ^bb19
    %55 = llvm.insertvalue %38, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %56 = llvm.insertvalue %22, %55[1] : !llvm.struct<(i32, i32, i32)> 
    %57 = llvm.insertvalue %23, %56[2] : !llvm.struct<(i32, i32, i32)> 
    %58 = llvm.insertvalue %46, %4[0] : !llvm.struct<(i64, i64)> 
    %59 = llvm.insertvalue %54, %58[1] : !llvm.struct<(i64, i64)> 
    %60 = llvm.insertvalue %57, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %61 = llvm.insertvalue %59, %60[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %62 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %63 = llvm.extractvalue %62[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %64 = llvm.extractvalue %63[0] : !llvm.struct<(i32, i32, i32)> 
    %65 = llvm.extractvalue %63[1] : !llvm.struct<(i32, i32, i32)> 
    %66 = llvm.extractvalue %63[2] : !llvm.struct<(i32, i32, i32)> 
    %67 = llvm.insertvalue %64, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %68 = llvm.insertvalue %65, %67[1] : !llvm.struct<(i32, i32, i32)> 
    %69 = llvm.insertvalue %66, %68[2] : !llvm.struct<(i32, i32, i32)> 
    %70 = llvm.insertvalue %69, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %71 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %72 = llvm.extractvalue %62[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %73 = llvm.extractvalue %62[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %74 = llvm.extractvalue %62[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %75 = llvm.extractvalue %62[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %76 = llvm.extractvalue %62[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %77 = llvm.add %26, %72 : i32
    %78 = llvm.sdiv %77, %13 : i32
    %79 = llvm.add %78, %11 : i32
    %80 = llvm.sub %17, %72 : i32
    %81 = llvm.sdiv %80, %13 : i32
    %82 = llvm.sub %17, %81 : i32
    %83 = llvm.icmp "slt" %72, %17 : i32
    %84 = llvm.icmp "sgt" %72, %17 : i32
    %85 = llvm.and %83, %8 : i1
    %86 = llvm.and %84, %9 : i1
    %87 = llvm.or %85, %86 : i1
    %88 = llvm.select %87, %79, %82 : i1, i32
    %89 = llvm.insertvalue %88, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %90 = llvm.insertvalue %73, %89[1] : !llvm.struct<(i32, i32, i32)> 
    %91 = llvm.insertvalue %74, %90[2] : !llvm.struct<(i32, i32, i32)> 
    %92 = llvm.insertvalue %75, %4[0] : !llvm.struct<(i64, i64)> 
    %93 = llvm.insertvalue %76, %92[1] : !llvm.struct<(i64, i64)> 
    %94 = llvm.insertvalue %91, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %95 = llvm.insertvalue %93, %94[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %96 = llvm.insertvalue %71, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %97 = llvm.insertvalue %95, %96[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %98 = llvm.extractvalue %70[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %99 = llvm.extractvalue %70[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %100 = llvm.extractvalue %70[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %101 = llvm.add %26, %98 : i32
    %102 = llvm.sdiv %101, %13 : i32
    %103 = llvm.add %102, %11 : i32
    %104 = llvm.sub %17, %98 : i32
    %105 = llvm.sdiv %104, %13 : i32
    %106 = llvm.sub %17, %105 : i32
    %107 = llvm.icmp "slt" %98, %17 : i32
    %108 = llvm.icmp "sgt" %98, %17 : i32
    %109 = llvm.and %107, %8 : i1
    %110 = llvm.and %108, %9 : i1
    %111 = llvm.or %109, %110 : i1
    %112 = llvm.select %111, %103, %106 : i1, i32
    %113 = llvm.insertvalue %112, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %114 = llvm.insertvalue %99, %113[1] : !llvm.struct<(i32, i32, i32)> 
    %115 = llvm.insertvalue %100, %114[2] : !llvm.struct<(i32, i32, i32)> 
    %116 = llvm.insertvalue %115, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %117 = llvm.insertvalue %14, %116[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %118 = llvm.insertvalue %14, %0[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %119 = llvm.insertvalue %117, %118[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %120 = llvm.extractvalue %60[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %121 = llvm.extractvalue %60[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %122 = llvm.extractvalue %60[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %123 = llvm.extractvalue %61[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %124 = llvm.extractvalue %61[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %125 = llvm.add %26, %120 : i32
    %126 = llvm.sdiv %125, %15 : i32
    %127 = llvm.add %126, %11 : i32
    %128 = llvm.sub %17, %120 : i32
    %129 = llvm.sdiv %128, %15 : i32
    %130 = llvm.sub %17, %129 : i32
    %131 = llvm.icmp "slt" %120, %17 : i32
    %132 = llvm.icmp "sgt" %120, %17 : i32
    %133 = llvm.and %131, %8 : i1
    %134 = llvm.and %132, %9 : i1
    %135 = llvm.or %133, %134 : i1
    %136 = llvm.select %135, %127, %130 : i1, i32
    %137 = llvm.insertvalue %136, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %138 = llvm.insertvalue %121, %137[1] : !llvm.struct<(i32, i32, i32)> 
    %139 = llvm.insertvalue %122, %138[2] : !llvm.struct<(i32, i32, i32)> 
    %140 = llvm.insertvalue %123, %4[0] : !llvm.struct<(i64, i64)> 
    %141 = llvm.insertvalue %124, %140[1] : !llvm.struct<(i64, i64)> 
    %142 = llvm.insertvalue %139, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %143 = llvm.insertvalue %141, %142[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %144 = llvm.insertvalue %19, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %145 = llvm.insertvalue %143, %144[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %146 = llvm.mul %88, %73 : i32
    %147 = llvm.mul %146, %74 : i32
    %148 = llvm.sext %147 : i32 to i64
    llvm.inline_asm has_side_effects asm_dialect = att {use_pdl = false} "", ""  : () -> ()
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%148, %16, %16) threads in (%18, %16, %16) : i64 dynamic_shared_memory_size %17 args(%97 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %145 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %119 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %64 : i32, %65 : i32, %66 : i32)
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> ()
    llvm.return
  }
}
