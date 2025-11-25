!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
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
    %19 = builtin.unrealized_conversion_cast %18 : i64 to index
    %20 = builtin.unrealized_conversion_cast %16 : i64 to index
    %21 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %22 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %23 = llvm.extractvalue %22[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %24 = llvm.extractvalue %22[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %25 = llvm.extractvalue %22[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %26 = llvm.extractvalue %22[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %27 = llvm.extractvalue %22[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %28 = llvm.select %9, %10, %11 : i1, i32
    %29 = llvm.add %28, %23 : i32
    %30 = llvm.sdiv %29, %12 : i32
    %31 = llvm.add %30, %11 : i32
    %32 = llvm.sub %17, %23 : i32
    %33 = llvm.sdiv %32, %12 : i32
    %34 = llvm.sub %17, %33 : i32
    %35 = llvm.icmp "slt" %23, %17 : i32
    %36 = llvm.icmp "sgt" %23, %17 : i32
    %37 = llvm.and %35, %8 : i1
    %38 = llvm.and %36, %9 : i1
    %39 = llvm.or %37, %38 : i1
    %40 = llvm.select %39, %31, %34 : i1, i32
    %41 = llvm.sdiv %26, %7 : i64
    %42 = llvm.icmp "ne" %41, %6 : i64
    llvm.cond_br %42, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    llvm.br ^bb9(%41 : i64)
  ^bb2:  // pred: ^bb0
    %43 = llvm.icmp "sgt" %26, %6 : i64
    llvm.cond_br %43, ^bb3(%11 : i32), ^bb4
  ^bb3(%44: i32):  // 2 preds: ^bb2, ^bb6
    llvm.br ^bb7
  ^bb4:  // pred: ^bb2
    %45 = llvm.icmp "eq" %26, %6 : i64
    llvm.cond_br %45, ^bb5(%17 : i32), ^bb5(%10 : i32)
  ^bb5(%46: i32):  // 2 preds: ^bb4, ^bb4
    llvm.br ^bb6
  ^bb6:  // pred: ^bb5
    llvm.br ^bb3(%46 : i32)
  ^bb7:  // pred: ^bb3
    llvm.br ^bb8
  ^bb8:  // pred: ^bb7
    %47 = llvm.sext %44 : i32 to i64
    llvm.br ^bb9(%47 : i64)
  ^bb9(%48: i64):  // 2 preds: ^bb1, ^bb8
    llvm.br ^bb10
  ^bb10:  // pred: ^bb9
    %49 = llvm.sdiv %27, %7 : i64
    %50 = llvm.icmp "ne" %49, %6 : i64
    llvm.cond_br %50, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    llvm.br ^bb19(%49 : i64)
  ^bb12:  // pred: ^bb10
    %51 = llvm.icmp "sgt" %27, %6 : i64
    llvm.cond_br %51, ^bb13(%11 : i32), ^bb14
  ^bb13(%52: i32):  // 2 preds: ^bb12, ^bb16
    llvm.br ^bb17
  ^bb14:  // pred: ^bb12
    %53 = llvm.icmp "eq" %27, %6 : i64
    llvm.cond_br %53, ^bb15(%17 : i32), ^bb15(%10 : i32)
  ^bb15(%54: i32):  // 2 preds: ^bb14, ^bb14
    llvm.br ^bb16
  ^bb16:  // pred: ^bb15
    llvm.br ^bb13(%54 : i32)
  ^bb17:  // pred: ^bb13
    llvm.br ^bb18
  ^bb18:  // pred: ^bb17
    %55 = llvm.sext %52 : i32 to i64
    llvm.br ^bb19(%55 : i64)
  ^bb19(%56: i64):  // 2 preds: ^bb11, ^bb18
    llvm.br ^bb20
  ^bb20:  // pred: ^bb19
    %57 = llvm.insertvalue %40, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %58 = llvm.insertvalue %24, %57[1] : !llvm.struct<(i32, i32, i32)> 
    %59 = llvm.insertvalue %25, %58[2] : !llvm.struct<(i32, i32, i32)> 
    %60 = llvm.insertvalue %48, %4[0] : !llvm.struct<(i64, i64)> 
    %61 = llvm.insertvalue %56, %60[1] : !llvm.struct<(i64, i64)> 
    %62 = llvm.insertvalue %59, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %63 = llvm.insertvalue %61, %62[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %64 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %65 = llvm.extractvalue %64[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %66 = llvm.extractvalue %65[0] : !llvm.struct<(i32, i32, i32)> 
    %67 = llvm.extractvalue %65[1] : !llvm.struct<(i32, i32, i32)> 
    %68 = llvm.extractvalue %65[2] : !llvm.struct<(i32, i32, i32)> 
    %69 = llvm.insertvalue %66, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %70 = llvm.insertvalue %67, %69[1] : !llvm.struct<(i32, i32, i32)> 
    %71 = llvm.insertvalue %68, %70[2] : !llvm.struct<(i32, i32, i32)> 
    %72 = llvm.insertvalue %71, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %73 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %74 = llvm.extractvalue %64[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %75 = llvm.extractvalue %64[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %76 = llvm.extractvalue %64[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %77 = llvm.extractvalue %64[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %78 = llvm.extractvalue %64[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %79 = llvm.add %28, %74 : i32
    %80 = llvm.sdiv %79, %13 : i32
    %81 = llvm.add %80, %11 : i32
    %82 = llvm.sub %17, %74 : i32
    %83 = llvm.sdiv %82, %13 : i32
    %84 = llvm.sub %17, %83 : i32
    %85 = llvm.icmp "slt" %74, %17 : i32
    %86 = llvm.icmp "sgt" %74, %17 : i32
    %87 = llvm.and %85, %8 : i1
    %88 = llvm.and %86, %9 : i1
    %89 = llvm.or %87, %88 : i1
    %90 = llvm.select %89, %81, %84 : i1, i32
    %91 = llvm.insertvalue %90, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %92 = llvm.insertvalue %75, %91[1] : !llvm.struct<(i32, i32, i32)> 
    %93 = llvm.insertvalue %76, %92[2] : !llvm.struct<(i32, i32, i32)> 
    %94 = llvm.insertvalue %77, %4[0] : !llvm.struct<(i64, i64)> 
    %95 = llvm.insertvalue %78, %94[1] : !llvm.struct<(i64, i64)> 
    %96 = llvm.insertvalue %93, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %97 = llvm.insertvalue %95, %96[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %98 = llvm.insertvalue %73, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %99 = llvm.insertvalue %97, %98[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %100 = builtin.unrealized_conversion_cast %99 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_f32_
    %101 = llvm.extractvalue %72[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %102 = llvm.extractvalue %72[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %103 = llvm.extractvalue %72[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %104 = llvm.add %28, %101 : i32
    %105 = llvm.sdiv %104, %13 : i32
    %106 = llvm.add %105, %11 : i32
    %107 = llvm.sub %17, %101 : i32
    %108 = llvm.sdiv %107, %13 : i32
    %109 = llvm.sub %17, %108 : i32
    %110 = llvm.icmp "slt" %101, %17 : i32
    %111 = llvm.icmp "sgt" %101, %17 : i32
    %112 = llvm.and %110, %8 : i1
    %113 = llvm.and %111, %9 : i1
    %114 = llvm.or %112, %113 : i1
    %115 = llvm.select %114, %106, %109 : i1, i32
    %116 = llvm.insertvalue %115, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %117 = llvm.insertvalue %102, %116[1] : !llvm.struct<(i32, i32, i32)> 
    %118 = llvm.insertvalue %103, %117[2] : !llvm.struct<(i32, i32, i32)> 
    %119 = llvm.insertvalue %118, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %120 = llvm.insertvalue %14, %119[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %121 = llvm.insertvalue %14, %0[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %122 = llvm.insertvalue %120, %121[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %123 = builtin.unrealized_conversion_cast %122 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %124 = llvm.extractvalue %62[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %125 = llvm.extractvalue %62[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %126 = llvm.extractvalue %62[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %127 = llvm.extractvalue %63[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %128 = llvm.extractvalue %63[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %129 = llvm.add %28, %124 : i32
    %130 = llvm.sdiv %129, %15 : i32
    %131 = llvm.add %130, %11 : i32
    %132 = llvm.sub %17, %124 : i32
    %133 = llvm.sdiv %132, %15 : i32
    %134 = llvm.sub %17, %133 : i32
    %135 = llvm.icmp "slt" %124, %17 : i32
    %136 = llvm.icmp "sgt" %124, %17 : i32
    %137 = llvm.and %135, %8 : i1
    %138 = llvm.and %136, %9 : i1
    %139 = llvm.or %137, %138 : i1
    %140 = llvm.select %139, %131, %134 : i1, i32
    %141 = llvm.insertvalue %140, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %142 = llvm.insertvalue %125, %141[1] : !llvm.struct<(i32, i32, i32)> 
    %143 = llvm.insertvalue %126, %142[2] : !llvm.struct<(i32, i32, i32)> 
    %144 = llvm.insertvalue %127, %4[0] : !llvm.struct<(i64, i64)> 
    %145 = llvm.insertvalue %128, %144[1] : !llvm.struct<(i64, i64)> 
    %146 = llvm.insertvalue %143, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %147 = llvm.insertvalue %145, %146[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %148 = llvm.insertvalue %21, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %149 = llvm.insertvalue %147, %148[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %150 = builtin.unrealized_conversion_cast %149 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_i8_
    %151 = llvm.mul %90, %75 : i32
    %152 = llvm.mul %151, %76 : i32
    %153 = llvm.sext %152 : i32 to i64
    %154 = builtin.unrealized_conversion_cast %153 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%154, %20, %20) threads in (%19, %20, %20)  dynamic_shared_memory_size %17 args(%100 : !memref_gmem_f32_, %150 : !memref_gmem_i8_, %123 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %66 : i32, %67 : i32, %68 : i32) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> ()
    llvm.return
  }
}
