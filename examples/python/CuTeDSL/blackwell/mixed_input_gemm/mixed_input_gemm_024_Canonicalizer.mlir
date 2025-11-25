!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
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
    llvm.br ^bb11(%41 : i64)
  ^bb2:  // pred: ^bb0
    %43 = llvm.icmp "sgt" %26, %6 : i64
    llvm.cond_br %43, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    llvm.br ^bb9(%11 : i32)
  ^bb4:  // pred: ^bb2
    %44 = llvm.icmp "eq" %26, %6 : i64
    llvm.cond_br %44, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    llvm.br ^bb7(%17 : i32)
  ^bb6:  // pred: ^bb4
    llvm.br ^bb7(%10 : i32)
  ^bb7(%45: i32):  // 2 preds: ^bb5, ^bb6
    llvm.br ^bb8
  ^bb8:  // pred: ^bb7
    llvm.br ^bb9(%45 : i32)
  ^bb9(%46: i32):  // 2 preds: ^bb3, ^bb8
    llvm.br ^bb10
  ^bb10:  // pred: ^bb9
    %47 = llvm.sext %46 : i32 to i64
    llvm.br ^bb11(%47 : i64)
  ^bb11(%48: i64):  // 2 preds: ^bb1, ^bb10
    llvm.br ^bb12
  ^bb12:  // pred: ^bb11
    %49 = llvm.sdiv %27, %7 : i64
    %50 = llvm.icmp "ne" %49, %6 : i64
    llvm.cond_br %50, ^bb13, ^bb14
  ^bb13:  // pred: ^bb12
    llvm.br ^bb23(%49 : i64)
  ^bb14:  // pred: ^bb12
    %51 = llvm.icmp "sgt" %27, %6 : i64
    llvm.cond_br %51, ^bb15, ^bb16
  ^bb15:  // pred: ^bb14
    llvm.br ^bb21(%11 : i32)
  ^bb16:  // pred: ^bb14
    %52 = llvm.icmp "eq" %27, %6 : i64
    llvm.cond_br %52, ^bb17, ^bb18
  ^bb17:  // pred: ^bb16
    llvm.br ^bb19(%17 : i32)
  ^bb18:  // pred: ^bb16
    llvm.br ^bb19(%10 : i32)
  ^bb19(%53: i32):  // 2 preds: ^bb17, ^bb18
    llvm.br ^bb20
  ^bb20:  // pred: ^bb19
    llvm.br ^bb21(%53 : i32)
  ^bb21(%54: i32):  // 2 preds: ^bb15, ^bb20
    llvm.br ^bb22
  ^bb22:  // pred: ^bb21
    %55 = llvm.sext %54 : i32 to i64
    llvm.br ^bb23(%55 : i64)
  ^bb23(%56: i64):  // 2 preds: ^bb13, ^bb22
    llvm.br ^bb24
  ^bb24:  // pred: ^bb23
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
    %79 = llvm.select %9, %10, %11 : i1, i32
    %80 = llvm.add %79, %74 : i32
    %81 = llvm.sdiv %80, %13 : i32
    %82 = llvm.add %81, %11 : i32
    %83 = llvm.sub %17, %74 : i32
    %84 = llvm.sdiv %83, %13 : i32
    %85 = llvm.sub %17, %84 : i32
    %86 = llvm.icmp "slt" %74, %17 : i32
    %87 = llvm.icmp "sgt" %74, %17 : i32
    %88 = llvm.and %86, %8 : i1
    %89 = llvm.and %87, %9 : i1
    %90 = llvm.or %88, %89 : i1
    %91 = llvm.select %90, %82, %85 : i1, i32
    %92 = llvm.insertvalue %91, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %93 = llvm.insertvalue %75, %92[1] : !llvm.struct<(i32, i32, i32)> 
    %94 = llvm.insertvalue %76, %93[2] : !llvm.struct<(i32, i32, i32)> 
    %95 = llvm.insertvalue %77, %4[0] : !llvm.struct<(i64, i64)> 
    %96 = llvm.insertvalue %78, %95[1] : !llvm.struct<(i64, i64)> 
    %97 = llvm.insertvalue %94, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %98 = llvm.insertvalue %96, %97[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %99 = llvm.insertvalue %73, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %100 = llvm.insertvalue %98, %99[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %101 = builtin.unrealized_conversion_cast %100 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_f32_
    %102 = llvm.extractvalue %72[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %103 = llvm.extractvalue %72[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %104 = llvm.extractvalue %72[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %105 = llvm.select %9, %10, %11 : i1, i32
    %106 = llvm.add %105, %102 : i32
    %107 = llvm.sdiv %106, %13 : i32
    %108 = llvm.add %107, %11 : i32
    %109 = llvm.sub %17, %102 : i32
    %110 = llvm.sdiv %109, %13 : i32
    %111 = llvm.sub %17, %110 : i32
    %112 = llvm.icmp "slt" %102, %17 : i32
    %113 = llvm.icmp "sgt" %102, %17 : i32
    %114 = llvm.and %112, %8 : i1
    %115 = llvm.and %113, %9 : i1
    %116 = llvm.or %114, %115 : i1
    %117 = llvm.select %116, %108, %111 : i1, i32
    %118 = llvm.insertvalue %117, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %119 = llvm.insertvalue %103, %118[1] : !llvm.struct<(i32, i32, i32)> 
    %120 = llvm.insertvalue %104, %119[2] : !llvm.struct<(i32, i32, i32)> 
    %121 = llvm.insertvalue %120, %2[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %122 = llvm.insertvalue %14, %121[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %123 = llvm.insertvalue %14, %0[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %124 = llvm.insertvalue %122, %123[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %125 = builtin.unrealized_conversion_cast %124 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %126 = llvm.extractvalue %62[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %127 = llvm.extractvalue %62[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %128 = llvm.extractvalue %62[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %129 = llvm.extractvalue %63[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %130 = llvm.extractvalue %63[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %131 = llvm.select %9, %10, %11 : i1, i32
    %132 = llvm.add %131, %126 : i32
    %133 = llvm.sdiv %132, %15 : i32
    %134 = llvm.add %133, %11 : i32
    %135 = llvm.sub %17, %126 : i32
    %136 = llvm.sdiv %135, %15 : i32
    %137 = llvm.sub %17, %136 : i32
    %138 = llvm.icmp "slt" %126, %17 : i32
    %139 = llvm.icmp "sgt" %126, %17 : i32
    %140 = llvm.and %138, %8 : i1
    %141 = llvm.and %139, %9 : i1
    %142 = llvm.or %140, %141 : i1
    %143 = llvm.select %142, %134, %137 : i1, i32
    %144 = llvm.insertvalue %143, %5[0] : !llvm.struct<(i32, i32, i32)> 
    %145 = llvm.insertvalue %127, %144[1] : !llvm.struct<(i32, i32, i32)> 
    %146 = llvm.insertvalue %128, %145[2] : !llvm.struct<(i32, i32, i32)> 
    %147 = llvm.insertvalue %129, %4[0] : !llvm.struct<(i64, i64)> 
    %148 = llvm.insertvalue %130, %147[1] : !llvm.struct<(i64, i64)> 
    %149 = llvm.insertvalue %146, %3[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %150 = llvm.insertvalue %148, %149[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %151 = llvm.insertvalue %21, %1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %152 = llvm.insertvalue %150, %151[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %153 = builtin.unrealized_conversion_cast %152 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_i8_
    %154 = llvm.mul %91, %75 : i32
    %155 = llvm.mul %154, %76 : i32
    %156 = llvm.sext %155 : i32 to i64
    %157 = builtin.unrealized_conversion_cast %156 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%157, %20, %20) threads in (%19, %20, %20)  dynamic_shared_memory_size %17 args(%101 : !memref_gmem_f32_, %153 : !memref_gmem_i8_, %125 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %66 : i32, %67 : i32, %68 : i32) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> ()
    llvm.return
  }
}
