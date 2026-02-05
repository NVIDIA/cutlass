#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, %arg3: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = llvm.mlir.constant(128 : i32) : i32
      %1 = llvm.mlir.constant(4 : i64) : i64
      %2 = llvm.mlir.constant(32 : i32) : i32
      %3 = llvm.mlir.constant(4 : i32) : i32
      %4 = llvm.mlir.constant(0 : i32) : i32
      %5 = llvm.mlir.constant(10 : i32) : i32
      %6 = llvm.mlir.constant(0 : i8) : i8
      %7 = llvm.mlir.constant(1 : i64) : i64
      %8 = llvm.mlir.constant(2 : i64) : i64
      %9 = llvm.mlir.constant(3 : i64) : i64
      %10 = llvm.mlir.constant(16 : i32) : i32
      %11 = llvm.mlir.constant(1 : i32) : i32
      %12 = llvm.alloca %10 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %13 = llvm.alloca %10 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %14 = llvm.alloca %10 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %15 = llvm.alloca %10 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %16 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %17 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %18 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %19 = llvm.extractvalue %18[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %20 = llvm.extractvalue %18[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %21 = llvm.extractvalue %20[0] : !llvm.struct<(i32, i32)> 
      %22 = llvm.extractvalue %18[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %23 = llvm.extractvalue %22[1] : !llvm.struct<(i64, i64)> 
      %24 = llvm.sdiv %17, %21 : i32
      %25 = llvm.srem %17, %21 : i32
      %26 = llvm.sext %25 : i32 to i64
      %27 = llvm.mul %26, %23 : i64
      %28 = llvm.mul %24, %0 : i32
      %29 = llvm.sext %28 : i32 to i64
      %30 = llvm.add %27, %29 : i64
      %31 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %32 = llvm.getelementptr %31[%30] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %33 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %34 = llvm.extractvalue %33[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %35 = llvm.extractvalue %33[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %36 = llvm.extractvalue %35[0] : !llvm.struct<(i32, i32)> 
      %37 = llvm.extractvalue %33[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %38 = llvm.extractvalue %37[1] : !llvm.struct<(i64, i64)> 
      %39 = llvm.sdiv %17, %36 : i32
      %40 = llvm.srem %17, %36 : i32
      %41 = llvm.sext %40 : i32 to i64
      %42 = llvm.mul %41, %38 : i64
      %43 = llvm.mul %39, %0 : i32
      %44 = llvm.sext %43 : i32 to i64
      %45 = llvm.add %42, %44 : i64
      %46 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %47 = llvm.getelementptr %46[%45] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %48 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %49 = llvm.extractvalue %48[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %50 = llvm.extractvalue %48[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %51 = llvm.extractvalue %50[0] : !llvm.struct<(i32, i32)> 
      %52 = llvm.extractvalue %48[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %53 = llvm.extractvalue %52[1] : !llvm.struct<(i64, i64)> 
      %54 = llvm.sdiv %17, %51 : i32
      %55 = llvm.srem %17, %51 : i32
      %56 = llvm.sext %55 : i32 to i64
      %57 = llvm.mul %56, %53 : i64
      %58 = llvm.mul %54, %0 : i32
      %59 = llvm.sext %58 : i32 to i64
      %60 = llvm.add %57, %59 : i64
      %61 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
      %62 = llvm.getelementptr %61[%60] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %63 = llvm.extractvalue %arg3[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
      %64 = llvm.extractvalue %63[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %65 = llvm.extractvalue %64[0] : !llvm.struct<(i32, i32)> 
      %66 = llvm.sdiv %17, %65 : i32
      %67 = llvm.srem %17, %65 : i32
      %68 = llvm.mul %67, %10 : i32
      %69 = llvm.mul %66, %0 : i32
      %70 = llvm.mul %19, %1 : i64
      %71 = llvm.sdiv %16, %2 : i32
      %72 = llvm.srem %16, %2 : i32
      %73 = llvm.mul %72, %3 : i32
      %74 = llvm.sext %71 : i32 to i64
      %75 = llvm.mul %74, %70 : i64
      %76 = llvm.sext %73 : i32 to i64
      %77 = llvm.add %76, %75 : i64
      %78 = llvm.getelementptr %32[%77] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %79 = llvm.mul %34, %1 : i64
      %80 = llvm.mul %74, %79 : i64
      %81 = llvm.add %76, %80 : i64
      %82 = llvm.getelementptr %47[%81] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %83 = llvm.mul %49, %1 : i64
      %84 = llvm.mul %74, %83 : i64
      %85 = llvm.add %76, %84 : i64
      %86 = llvm.getelementptr %62[%85] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %87 = llvm.mul %71, %3 : i32
      %88 = llvm.add %68, %87 : i32
      %89 = llvm.add %69, %73 : i32
      llvm.br ^bb1(%4 : i32)
    ^bb1(%90: i32):  // 2 preds: ^bb0, ^bb2
      %91 = llvm.icmp "slt" %90, %10 : i32
      llvm.cond_br %91, ^bb2, ^bb3
    ^bb2:  // pred: ^bb1
      %92 = llvm.srem %90, %10 : i32
      %93 = llvm.sdiv %92, %3 : i32
      %94 = llvm.srem %92, %3 : i32
      %95 = llvm.add %88, %93 : i32
      %96 = llvm.add %89, %94 : i32
      %97 = llvm.icmp "slt" %95, %arg4 : i32
      %98 = llvm.icmp "slt" %96, %arg5 : i32
      %99 = llvm.and %97, %98 : i1
      %100 = llvm.zext %99 : i1 to i8
      %101 = llvm.srem %90, %10 : i32
      %102 = llvm.sdiv %101, %3 : i32
      %103 = llvm.srem %101, %3 : i32
      %104 = llvm.mul %102, %3 : i32
      %105 = llvm.add %103, %104 : i32
      %106 = llvm.getelementptr %12[%105] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %107 = llvm.ptrtoint %106 : !llvm.ptr to i64
      %108 = llvm.inttoptr %107 : i64 to !llvm.ptr
      llvm.store %100, %108 {alignment = 1 : i64} : i8, !llvm.ptr
      %109 = llvm.add %90, %11 : i32
      llvm.br ^bb1(%109 : i32)
    ^bb3:  // pred: ^bb1
      %110 = llvm.getelementptr %12[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %111 = llvm.getelementptr %12[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %112 = llvm.getelementptr %12[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %113 = llvm.getelementptr %12[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %114 = llvm.getelementptr %12[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %115 = llvm.getelementptr %12[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %116 = llvm.getelementptr %12[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %117 = llvm.getelementptr %12[8] : (!llvm.ptr) -> !llvm.ptr, i8
      %118 = llvm.getelementptr %12[9] : (!llvm.ptr) -> !llvm.ptr, i8
      %119 = llvm.getelementptr %12[10] : (!llvm.ptr) -> !llvm.ptr, i8
      %120 = llvm.getelementptr %12[11] : (!llvm.ptr) -> !llvm.ptr, i8
      %121 = llvm.getelementptr %12[12] : (!llvm.ptr) -> !llvm.ptr, i8
      %122 = llvm.getelementptr %12[13] : (!llvm.ptr) -> !llvm.ptr, i8
      %123 = llvm.getelementptr %12[14] : (!llvm.ptr) -> !llvm.ptr, i8
      %124 = llvm.getelementptr %12[15] : (!llvm.ptr) -> !llvm.ptr, i8
      llvm.br ^bb4(%4 : i32)
    ^bb4(%125: i32):  // 2 preds: ^bb3, ^bb40
      %126 = llvm.icmp "slt" %125, %5 : i32
      llvm.cond_br %126, ^bb5, ^bb41
    ^bb5:  // pred: ^bb4
      llvm.br ^bb6(%4 : i32)
    ^bb6(%127: i32):  // 2 preds: ^bb5, ^bb39
      %128 = llvm.icmp "slt" %127, %11 : i32
      llvm.cond_br %128, ^bb7, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %129 = llvm.load %12 : !llvm.ptr -> i8
      %130 = llvm.icmp "ne" %129, %6 : i8
      llvm.cond_br %130, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %131 = llvm.load %82 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %131, %14 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %132 = llvm.load %110 : !llvm.ptr -> i8
      %133 = llvm.icmp "ne" %132, %6 : i8
      llvm.cond_br %133, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %134 = llvm.getelementptr %82[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %135 = llvm.getelementptr %14[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %136 = llvm.load %134 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %136, %135 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %137 = llvm.load %111 : !llvm.ptr -> i8
      %138 = llvm.icmp "ne" %137, %6 : i8
      llvm.cond_br %138, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %139 = llvm.getelementptr %82[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %140 = llvm.getelementptr %14[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %141 = llvm.load %139 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %141, %140 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %142 = llvm.load %112 : !llvm.ptr -> i8
      %143 = llvm.icmp "ne" %142, %6 : i8
      llvm.cond_br %143, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %144 = llvm.getelementptr %82[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %145 = llvm.getelementptr %14[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %146 = llvm.load %144 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %146, %145 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %147 = llvm.load %113 : !llvm.ptr -> i8
      %148 = llvm.icmp "ne" %147, %6 : i8
      llvm.cond_br %148, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %149 = llvm.getelementptr %82[%34] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %150 = llvm.getelementptr %14[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %152 = llvm.load %114 : !llvm.ptr -> i8
      %153 = llvm.icmp "ne" %152, %6 : i8
      llvm.cond_br %153, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %154 = llvm.add %34, %7 : i64
      %155 = llvm.getelementptr %82[%154] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %156 = llvm.getelementptr %14[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %157 = llvm.load %155 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %157, %156 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %158 = llvm.load %115 : !llvm.ptr -> i8
      %159 = llvm.icmp "ne" %158, %6 : i8
      llvm.cond_br %159, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %160 = llvm.add %34, %8 : i64
      %161 = llvm.getelementptr %82[%160] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %162 = llvm.getelementptr %14[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %163 = llvm.load %161 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %163, %162 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %164 = llvm.load %116 : !llvm.ptr -> i8
      %165 = llvm.icmp "ne" %164, %6 : i8
      llvm.cond_br %165, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %166 = llvm.add %34, %9 : i64
      %167 = llvm.getelementptr %82[%166] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %168 = llvm.getelementptr %14[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %170 = llvm.load %117 : !llvm.ptr -> i8
      %171 = llvm.icmp "ne" %170, %6 : i8
      llvm.cond_br %171, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      %172 = llvm.mul %34, %8 : i64
      %173 = llvm.getelementptr %82[%172] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %174 = llvm.getelementptr %14[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %175 = llvm.load %173 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %175, %174 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %176 = llvm.load %118 : !llvm.ptr -> i8
      %177 = llvm.icmp "ne" %176, %6 : i8
      llvm.cond_br %177, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %178 = llvm.mul %34, %8 : i64
      %179 = llvm.add %178, %7 : i64
      %180 = llvm.getelementptr %82[%179] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %181 = llvm.getelementptr %14[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb27
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %183 = llvm.load %119 : !llvm.ptr -> i8
      %184 = llvm.icmp "ne" %183, %6 : i8
      llvm.cond_br %184, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %185 = llvm.mul %34, %8 : i64
      %186 = llvm.add %185, %8 : i64
      %187 = llvm.getelementptr %82[%186] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %188 = llvm.getelementptr %14[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %189 = llvm.load %187 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %189, %188 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      %190 = llvm.load %120 : !llvm.ptr -> i8
      %191 = llvm.icmp "ne" %190, %6 : i8
      llvm.cond_br %191, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %192 = llvm.mul %34, %8 : i64
      %193 = llvm.add %192, %9 : i64
      %194 = llvm.getelementptr %82[%193] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %195 = llvm.getelementptr %14[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %196 = llvm.load %194 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %196, %195 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb31
    ^bb31:  // 2 preds: ^bb29, ^bb30
      %197 = llvm.load %121 : !llvm.ptr -> i8
      %198 = llvm.icmp "ne" %197, %6 : i8
      llvm.cond_br %198, ^bb32, ^bb33
    ^bb32:  // pred: ^bb31
      %199 = llvm.mul %34, %9 : i64
      %200 = llvm.getelementptr %82[%199] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %201 = llvm.getelementptr %14[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %202 = llvm.load %200 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %202, %201 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb33
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %203 = llvm.load %122 : !llvm.ptr -> i8
      %204 = llvm.icmp "ne" %203, %6 : i8
      llvm.cond_br %204, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %205 = llvm.mul %34, %9 : i64
      %206 = llvm.add %205, %7 : i64
      %207 = llvm.getelementptr %82[%206] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %208 = llvm.getelementptr %14[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb35
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %210 = llvm.load %123 : !llvm.ptr -> i8
      %211 = llvm.icmp "ne" %210, %6 : i8
      llvm.cond_br %211, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %212 = llvm.mul %34, %9 : i64
      %213 = llvm.add %212, %8 : i64
      %214 = llvm.getelementptr %82[%213] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %215 = llvm.getelementptr %14[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %216 = llvm.load %214 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %216, %215 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %217 = llvm.load %124 : !llvm.ptr -> i8
      %218 = llvm.icmp "ne" %217, %6 : i8
      llvm.cond_br %218, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %219 = llvm.mul %34, %9 : i64
      %220 = llvm.add %219, %9 : i64
      %221 = llvm.getelementptr %82[%220] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %222 = llvm.getelementptr %14[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %223 = llvm.load %221 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %223, %222 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb39
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %224 = llvm.add %127, %11 : i32
      llvm.br ^bb6(%224 : i32)
    ^bb40:  // pred: ^bb6
      %225 = llvm.add %125, %11 : i32
      llvm.br ^bb4(%225 : i32)
    ^bb41:  // pred: ^bb4
      llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
      %226 = llvm.getelementptr %12[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %227 = llvm.getelementptr %12[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %228 = llvm.getelementptr %12[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %229 = llvm.getelementptr %12[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %230 = llvm.getelementptr %12[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %231 = llvm.getelementptr %12[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %232 = llvm.getelementptr %12[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %233 = llvm.getelementptr %12[8] : (!llvm.ptr) -> !llvm.ptr, i8
      %234 = llvm.getelementptr %12[9] : (!llvm.ptr) -> !llvm.ptr, i8
      %235 = llvm.getelementptr %12[10] : (!llvm.ptr) -> !llvm.ptr, i8
      %236 = llvm.getelementptr %12[11] : (!llvm.ptr) -> !llvm.ptr, i8
      %237 = llvm.getelementptr %12[12] : (!llvm.ptr) -> !llvm.ptr, i8
      %238 = llvm.getelementptr %12[13] : (!llvm.ptr) -> !llvm.ptr, i8
      %239 = llvm.getelementptr %12[14] : (!llvm.ptr) -> !llvm.ptr, i8
      %240 = llvm.getelementptr %12[15] : (!llvm.ptr) -> !llvm.ptr, i8
      llvm.br ^bb42(%4 : i32)
    ^bb42(%241: i32):  // 2 preds: ^bb41, ^bb78
      %242 = llvm.icmp "slt" %241, %5 : i32
      llvm.cond_br %242, ^bb43, ^bb79
    ^bb43:  // pred: ^bb42
      llvm.br ^bb44(%4 : i32)
    ^bb44(%243: i32):  // 2 preds: ^bb43, ^bb77
      %244 = llvm.icmp "slt" %243, %11 : i32
      llvm.cond_br %244, ^bb45, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %245 = llvm.load %12 : !llvm.ptr -> i8
      %246 = llvm.icmp "ne" %245, %6 : i8
      llvm.cond_br %246, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %247 = llvm.load %78 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %247, %15 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %248 = llvm.load %226 : !llvm.ptr -> i8
      %249 = llvm.icmp "ne" %248, %6 : i8
      llvm.cond_br %249, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %250 = llvm.getelementptr %78[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %251 = llvm.getelementptr %15[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %252 = llvm.load %250 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %252, %251 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %253 = llvm.load %227 : !llvm.ptr -> i8
      %254 = llvm.icmp "ne" %253, %6 : i8
      llvm.cond_br %254, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %255 = llvm.getelementptr %78[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %256 = llvm.getelementptr %15[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %257 = llvm.load %255 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %257, %256 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %258 = llvm.load %228 : !llvm.ptr -> i8
      %259 = llvm.icmp "ne" %258, %6 : i8
      llvm.cond_br %259, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %260 = llvm.getelementptr %78[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %261 = llvm.getelementptr %15[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %262 = llvm.load %260 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %262, %261 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %263 = llvm.load %229 : !llvm.ptr -> i8
      %264 = llvm.icmp "ne" %263, %6 : i8
      llvm.cond_br %264, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %265 = llvm.getelementptr %78[%19] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %266 = llvm.getelementptr %15[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %267 = llvm.load %265 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %267, %266 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %268 = llvm.load %230 : !llvm.ptr -> i8
      %269 = llvm.icmp "ne" %268, %6 : i8
      llvm.cond_br %269, ^bb56, ^bb57
    ^bb56:  // pred: ^bb55
      %270 = llvm.add %19, %7 : i64
      %271 = llvm.getelementptr %78[%270] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %272 = llvm.getelementptr %15[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %273 = llvm.load %271 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %273, %272 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb57
    ^bb57:  // 2 preds: ^bb55, ^bb56
      %274 = llvm.load %231 : !llvm.ptr -> i8
      %275 = llvm.icmp "ne" %274, %6 : i8
      llvm.cond_br %275, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %276 = llvm.add %19, %8 : i64
      %277 = llvm.getelementptr %78[%276] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %278 = llvm.getelementptr %15[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %279 = llvm.load %277 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %279, %278 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb59
    ^bb59:  // 2 preds: ^bb57, ^bb58
      %280 = llvm.load %232 : !llvm.ptr -> i8
      %281 = llvm.icmp "ne" %280, %6 : i8
      llvm.cond_br %281, ^bb60, ^bb61
    ^bb60:  // pred: ^bb59
      %282 = llvm.add %19, %9 : i64
      %283 = llvm.getelementptr %78[%282] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %284 = llvm.getelementptr %15[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %285 = llvm.load %283 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %285, %284 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb61
    ^bb61:  // 2 preds: ^bb59, ^bb60
      %286 = llvm.load %233 : !llvm.ptr -> i8
      %287 = llvm.icmp "ne" %286, %6 : i8
      llvm.cond_br %287, ^bb62, ^bb63
    ^bb62:  // pred: ^bb61
      %288 = llvm.mul %19, %8 : i64
      %289 = llvm.getelementptr %78[%288] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %290 = llvm.getelementptr %15[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %291 = llvm.load %289 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %291, %290 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb63
    ^bb63:  // 2 preds: ^bb61, ^bb62
      %292 = llvm.load %234 : !llvm.ptr -> i8
      %293 = llvm.icmp "ne" %292, %6 : i8
      llvm.cond_br %293, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      %294 = llvm.mul %19, %8 : i64
      %295 = llvm.add %294, %7 : i64
      %296 = llvm.getelementptr %78[%295] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %297 = llvm.getelementptr %15[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %298 = llvm.load %296 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %298, %297 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %299 = llvm.load %235 : !llvm.ptr -> i8
      %300 = llvm.icmp "ne" %299, %6 : i8
      llvm.cond_br %300, ^bb66, ^bb67
    ^bb66:  // pred: ^bb65
      %301 = llvm.mul %19, %8 : i64
      %302 = llvm.add %301, %8 : i64
      %303 = llvm.getelementptr %78[%302] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %304 = llvm.getelementptr %15[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %305 = llvm.load %303 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %305, %304 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb67
    ^bb67:  // 2 preds: ^bb65, ^bb66
      %306 = llvm.load %236 : !llvm.ptr -> i8
      %307 = llvm.icmp "ne" %306, %6 : i8
      llvm.cond_br %307, ^bb68, ^bb69
    ^bb68:  // pred: ^bb67
      %308 = llvm.mul %19, %8 : i64
      %309 = llvm.add %308, %9 : i64
      %310 = llvm.getelementptr %78[%309] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %311 = llvm.getelementptr %15[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %312 = llvm.load %310 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %312, %311 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb69
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %313 = llvm.load %237 : !llvm.ptr -> i8
      %314 = llvm.icmp "ne" %313, %6 : i8
      llvm.cond_br %314, ^bb70, ^bb71
    ^bb70:  // pred: ^bb69
      %315 = llvm.mul %19, %9 : i64
      %316 = llvm.getelementptr %78[%315] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %317 = llvm.getelementptr %15[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %318 = llvm.load %316 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %318, %317 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb71
    ^bb71:  // 2 preds: ^bb69, ^bb70
      %319 = llvm.load %238 : !llvm.ptr -> i8
      %320 = llvm.icmp "ne" %319, %6 : i8
      llvm.cond_br %320, ^bb72, ^bb73
    ^bb72:  // pred: ^bb71
      %321 = llvm.mul %19, %9 : i64
      %322 = llvm.add %321, %7 : i64
      %323 = llvm.getelementptr %78[%322] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %324 = llvm.getelementptr %15[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %325 = llvm.load %323 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %325, %324 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb73
    ^bb73:  // 2 preds: ^bb71, ^bb72
      %326 = llvm.load %239 : !llvm.ptr -> i8
      %327 = llvm.icmp "ne" %326, %6 : i8
      llvm.cond_br %327, ^bb74, ^bb75
    ^bb74:  // pred: ^bb73
      %328 = llvm.mul %19, %9 : i64
      %329 = llvm.add %328, %8 : i64
      %330 = llvm.getelementptr %78[%329] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %331 = llvm.getelementptr %15[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %332 = llvm.load %330 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %332, %331 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb75
    ^bb75:  // 2 preds: ^bb73, ^bb74
      %333 = llvm.load %240 : !llvm.ptr -> i8
      %334 = llvm.icmp "ne" %333, %6 : i8
      llvm.cond_br %334, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %335 = llvm.mul %19, %9 : i64
      %336 = llvm.add %335, %9 : i64
      %337 = llvm.getelementptr %78[%336] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %338 = llvm.getelementptr %15[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %339 = llvm.load %337 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %339, %338 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      llvm.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %340 = llvm.add %243, %11 : i32
      llvm.br ^bb44(%340 : i32)
    ^bb78:  // pred: ^bb44
      %341 = llvm.add %241, %11 : i32
      llvm.br ^bb42(%341 : i32)
    ^bb79:  // pred: ^bb42
      llvm.br ^bb80(%4 : i32)
    ^bb80(%342: i32):  // 2 preds: ^bb79, ^bb81
      %343 = llvm.icmp "slt" %342, %5 : i32
      llvm.cond_br %343, ^bb81, ^bb82
    ^bb81:  // pred: ^bb80
      %344 = llvm.load %15 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf32>
      %345 = llvm.load %14 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf32>
      %346 = llvm.fadd %344, %345 : vector<16xf32>
      llvm.store %346, %13 {alignment = 32 : i64} : vector<16xf32>, !llvm.ptr
      %347 = llvm.add %342, %11 : i32
      llvm.br ^bb80(%347 : i32)
    ^bb82:  // pred: ^bb80
      %348 = llvm.getelementptr %12[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %349 = llvm.getelementptr %12[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %350 = llvm.getelementptr %12[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %351 = llvm.getelementptr %12[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %352 = llvm.getelementptr %12[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %353 = llvm.getelementptr %12[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %354 = llvm.getelementptr %12[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %355 = llvm.getelementptr %12[8] : (!llvm.ptr) -> !llvm.ptr, i8
      %356 = llvm.getelementptr %12[9] : (!llvm.ptr) -> !llvm.ptr, i8
      %357 = llvm.getelementptr %12[10] : (!llvm.ptr) -> !llvm.ptr, i8
      %358 = llvm.getelementptr %12[11] : (!llvm.ptr) -> !llvm.ptr, i8
      %359 = llvm.getelementptr %12[12] : (!llvm.ptr) -> !llvm.ptr, i8
      %360 = llvm.getelementptr %12[13] : (!llvm.ptr) -> !llvm.ptr, i8
      %361 = llvm.getelementptr %12[14] : (!llvm.ptr) -> !llvm.ptr, i8
      %362 = llvm.getelementptr %12[15] : (!llvm.ptr) -> !llvm.ptr, i8
      llvm.br ^bb83(%4 : i32)
    ^bb83(%363: i32):  // 2 preds: ^bb82, ^bb116
      %364 = llvm.icmp "slt" %363, %11 : i32
      llvm.cond_br %364, ^bb84, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      %365 = llvm.load %12 : !llvm.ptr -> i8
      %366 = llvm.icmp "ne" %365, %6 : i8
      llvm.cond_br %366, ^bb85, ^bb86
    ^bb85:  // pred: ^bb84
      %367 = llvm.load %13 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %367, %86 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb86
    ^bb86:  // 2 preds: ^bb84, ^bb85
      %368 = llvm.load %348 : !llvm.ptr -> i8
      %369 = llvm.icmp "ne" %368, %6 : i8
      llvm.cond_br %369, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %370 = llvm.getelementptr %13[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %371 = llvm.getelementptr %86[1] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %372 = llvm.load %370 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %372, %371 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %373 = llvm.load %349 : !llvm.ptr -> i8
      %374 = llvm.icmp "ne" %373, %6 : i8
      llvm.cond_br %374, ^bb89, ^bb90
    ^bb89:  // pred: ^bb88
      %375 = llvm.getelementptr %13[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %376 = llvm.getelementptr %86[2] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %377 = llvm.load %375 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %377, %376 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb90
    ^bb90:  // 2 preds: ^bb88, ^bb89
      %378 = llvm.load %350 : !llvm.ptr -> i8
      %379 = llvm.icmp "ne" %378, %6 : i8
      llvm.cond_br %379, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %380 = llvm.getelementptr %13[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %381 = llvm.getelementptr %86[3] : (!llvm.ptr<1>) -> !llvm.ptr<1>, f32
      %382 = llvm.load %380 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %382, %381 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb92
    ^bb92:  // 2 preds: ^bb90, ^bb91
      %383 = llvm.load %351 : !llvm.ptr -> i8
      %384 = llvm.icmp "ne" %383, %6 : i8
      llvm.cond_br %384, ^bb93, ^bb94
    ^bb93:  // pred: ^bb92
      %385 = llvm.getelementptr %13[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %386 = llvm.getelementptr %86[%49] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %387 = llvm.load %385 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %387, %386 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb94
    ^bb94:  // 2 preds: ^bb92, ^bb93
      %388 = llvm.load %352 : !llvm.ptr -> i8
      %389 = llvm.icmp "ne" %388, %6 : i8
      llvm.cond_br %389, ^bb95, ^bb96
    ^bb95:  // pred: ^bb94
      %390 = llvm.getelementptr %13[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %391 = llvm.add %49, %7 : i64
      %392 = llvm.getelementptr %86[%391] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %393 = llvm.load %390 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %393, %392 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb96
    ^bb96:  // 2 preds: ^bb94, ^bb95
      %394 = llvm.load %353 : !llvm.ptr -> i8
      %395 = llvm.icmp "ne" %394, %6 : i8
      llvm.cond_br %395, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      %396 = llvm.getelementptr %13[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %397 = llvm.add %49, %8 : i64
      %398 = llvm.getelementptr %86[%397] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %399 = llvm.load %396 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %399, %398 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %400 = llvm.load %354 : !llvm.ptr -> i8
      %401 = llvm.icmp "ne" %400, %6 : i8
      llvm.cond_br %401, ^bb99, ^bb100
    ^bb99:  // pred: ^bb98
      %402 = llvm.getelementptr %13[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %403 = llvm.add %49, %9 : i64
      %404 = llvm.getelementptr %86[%403] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %405 = llvm.load %402 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %405, %404 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb100
    ^bb100:  // 2 preds: ^bb98, ^bb99
      %406 = llvm.load %355 : !llvm.ptr -> i8
      %407 = llvm.icmp "ne" %406, %6 : i8
      llvm.cond_br %407, ^bb101, ^bb102
    ^bb101:  // pred: ^bb100
      %408 = llvm.getelementptr %13[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %409 = llvm.mul %49, %8 : i64
      %410 = llvm.getelementptr %86[%409] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %411 = llvm.load %408 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %411, %410 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb102
    ^bb102:  // 2 preds: ^bb100, ^bb101
      %412 = llvm.load %356 : !llvm.ptr -> i8
      %413 = llvm.icmp "ne" %412, %6 : i8
      llvm.cond_br %413, ^bb103, ^bb104
    ^bb103:  // pred: ^bb102
      %414 = llvm.getelementptr %13[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %415 = llvm.mul %49, %8 : i64
      %416 = llvm.add %415, %7 : i64
      %417 = llvm.getelementptr %86[%416] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %418 = llvm.load %414 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %418, %417 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb104
    ^bb104:  // 2 preds: ^bb102, ^bb103
      %419 = llvm.load %357 : !llvm.ptr -> i8
      %420 = llvm.icmp "ne" %419, %6 : i8
      llvm.cond_br %420, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %421 = llvm.getelementptr %13[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %422 = llvm.mul %49, %8 : i64
      %423 = llvm.add %422, %8 : i64
      %424 = llvm.getelementptr %86[%423] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %425 = llvm.load %421 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %425, %424 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      %426 = llvm.load %358 : !llvm.ptr -> i8
      %427 = llvm.icmp "ne" %426, %6 : i8
      llvm.cond_br %427, ^bb107, ^bb108
    ^bb107:  // pred: ^bb106
      %428 = llvm.getelementptr %13[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %429 = llvm.mul %49, %8 : i64
      %430 = llvm.add %429, %9 : i64
      %431 = llvm.getelementptr %86[%430] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %432 = llvm.load %428 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %432, %431 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb108
    ^bb108:  // 2 preds: ^bb106, ^bb107
      %433 = llvm.load %359 : !llvm.ptr -> i8
      %434 = llvm.icmp "ne" %433, %6 : i8
      llvm.cond_br %434, ^bb109, ^bb110
    ^bb109:  // pred: ^bb108
      %435 = llvm.getelementptr %13[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %436 = llvm.mul %49, %9 : i64
      %437 = llvm.getelementptr %86[%436] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %438 = llvm.load %435 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %438, %437 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb110
    ^bb110:  // 2 preds: ^bb108, ^bb109
      %439 = llvm.load %360 : !llvm.ptr -> i8
      %440 = llvm.icmp "ne" %439, %6 : i8
      llvm.cond_br %440, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      %441 = llvm.getelementptr %13[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %442 = llvm.mul %49, %9 : i64
      %443 = llvm.add %442, %7 : i64
      %444 = llvm.getelementptr %86[%443] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %445 = llvm.load %441 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %445, %444 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %446 = llvm.load %361 : !llvm.ptr -> i8
      %447 = llvm.icmp "ne" %446, %6 : i8
      llvm.cond_br %447, ^bb113, ^bb114
    ^bb113:  // pred: ^bb112
      %448 = llvm.getelementptr %13[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %449 = llvm.mul %49, %9 : i64
      %450 = llvm.add %449, %8 : i64
      %451 = llvm.getelementptr %86[%450] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %452 = llvm.load %448 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %452, %451 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb114
    ^bb114:  // 2 preds: ^bb112, ^bb113
      %453 = llvm.load %362 : !llvm.ptr -> i8
      %454 = llvm.icmp "ne" %453, %6 : i8
      llvm.cond_br %454, ^bb115, ^bb116
    ^bb115:  // pred: ^bb114
      %455 = llvm.getelementptr %13[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %456 = llvm.mul %49, %9 : i64
      %457 = llvm.add %456, %9 : i64
      %458 = llvm.getelementptr %86[%457] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %459 = llvm.load %455 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %459, %458 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      llvm.br ^bb116
    ^bb116:  // 2 preds: ^bb114, ^bb115
      %460 = llvm.add %363, %11 : i32
      llvm.br ^bb83(%460 : i32)
    ^bb117:  // pred: ^bb83
      llvm.return
    }
  }
  llvm.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg3: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>
    %1 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %2 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>
    %3 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
    %4 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %5 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
    %6 = llvm.mlir.constant(false) : i1
    %7 = llvm.mlir.constant(true) : i1
    %8 = llvm.mlir.constant(-1 : i32) : i32
    %9 = llvm.mlir.constant(0 : i64) : i64
    %10 = llvm.mlir.constant(1 : i32) : i32
    %11 = llvm.mlir.constant(0 : i32) : i32
    %12 = llvm.mlir.poison : !llvm.struct<()>
    %13 = llvm.mlir.constant(128 : i32) : i32
    %14 = llvm.mlir.constant(16 : i64) : i64
    %15 = llvm.mlir.constant(16 : i32) : i32
    %16 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %17 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %18 = llvm.extractvalue %17[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %19 = llvm.extractvalue %17[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %20 = llvm.extractvalue %17[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %21 = llvm.select %7, %8, %10 : i1, i32
    %22 = llvm.add %21, %18 : i32
    %23 = llvm.sdiv %22, %15 : i32
    %24 = llvm.add %23, %10 : i32
    %25 = llvm.sub %11, %18 : i32
    %26 = llvm.sdiv %25, %15 : i32
    %27 = llvm.sub %11, %26 : i32
    %28 = llvm.icmp "slt" %18, %11 : i32
    %29 = llvm.icmp "sgt" %18, %11 : i32
    %30 = llvm.and %28, %6 : i1
    %31 = llvm.and %29, %7 : i1
    %32 = llvm.or %30, %31 : i1
    %33 = llvm.select %32, %24, %27 : i1, i32
    %34 = llvm.mul %20, %14 : i64
    %35 = llvm.select %7, %8, %10 : i1, i32
    %36 = llvm.add %35, %19 : i32
    %37 = llvm.sdiv %36, %13 : i32
    %38 = llvm.add %37, %10 : i32
    %39 = llvm.sub %11, %19 : i32
    %40 = llvm.sdiv %39, %13 : i32
    %41 = llvm.sub %11, %40 : i32
    %42 = llvm.icmp "slt" %19, %11 : i32
    %43 = llvm.icmp "sgt" %19, %11 : i32
    %44 = llvm.and %42, %6 : i1
    %45 = llvm.and %43, %7 : i1
    %46 = llvm.or %44, %45 : i1
    %47 = llvm.select %46, %38, %41 : i1, i32
    %48 = llvm.insertvalue %33, %5[0] : !llvm.struct<(i32, i32)> 
    %49 = llvm.insertvalue %47, %48[1] : !llvm.struct<(i32, i32)> 
    %50 = llvm.insertvalue %20, %4[0] : !llvm.struct<(i64, i64)> 
    %51 = llvm.insertvalue %34, %50[1] : !llvm.struct<(i64, i64)> 
    %52 = llvm.insertvalue %49, %3[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %53 = llvm.insertvalue %51, %52[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %54 = llvm.insertvalue %16, %2[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %55 = llvm.insertvalue %53, %54[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %56 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %57 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %58 = llvm.extractvalue %57[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %59 = llvm.extractvalue %57[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %60 = llvm.extractvalue %57[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %61 = llvm.select %7, %8, %10 : i1, i32
    %62 = llvm.add %61, %58 : i32
    %63 = llvm.sdiv %62, %15 : i32
    %64 = llvm.add %63, %10 : i32
    %65 = llvm.sub %11, %58 : i32
    %66 = llvm.sdiv %65, %15 : i32
    %67 = llvm.sub %11, %66 : i32
    %68 = llvm.icmp "slt" %58, %11 : i32
    %69 = llvm.icmp "sgt" %58, %11 : i32
    %70 = llvm.and %68, %6 : i1
    %71 = llvm.and %69, %7 : i1
    %72 = llvm.or %70, %71 : i1
    %73 = llvm.select %72, %64, %67 : i1, i32
    %74 = llvm.mul %60, %14 : i64
    %75 = llvm.select %7, %8, %10 : i1, i32
    %76 = llvm.add %75, %59 : i32
    %77 = llvm.sdiv %76, %13 : i32
    %78 = llvm.add %77, %10 : i32
    %79 = llvm.sub %11, %59 : i32
    %80 = llvm.sdiv %79, %13 : i32
    %81 = llvm.sub %11, %80 : i32
    %82 = llvm.icmp "slt" %59, %11 : i32
    %83 = llvm.icmp "sgt" %59, %11 : i32
    %84 = llvm.and %82, %6 : i1
    %85 = llvm.and %83, %7 : i1
    %86 = llvm.or %84, %85 : i1
    %87 = llvm.select %86, %78, %81 : i1, i32
    %88 = llvm.insertvalue %73, %5[0] : !llvm.struct<(i32, i32)> 
    %89 = llvm.insertvalue %87, %88[1] : !llvm.struct<(i32, i32)> 
    %90 = llvm.insertvalue %60, %4[0] : !llvm.struct<(i64, i64)> 
    %91 = llvm.insertvalue %74, %90[1] : !llvm.struct<(i64, i64)> 
    %92 = llvm.insertvalue %89, %3[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %93 = llvm.insertvalue %91, %92[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %94 = llvm.insertvalue %56, %2[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %95 = llvm.insertvalue %93, %94[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %96 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %97 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %98 = llvm.extractvalue %97[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %99 = llvm.extractvalue %97[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %100 = llvm.extractvalue %97[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %101 = llvm.select %7, %8, %10 : i1, i32
    %102 = llvm.add %101, %98 : i32
    %103 = llvm.sdiv %102, %15 : i32
    %104 = llvm.add %103, %10 : i32
    %105 = llvm.sub %11, %98 : i32
    %106 = llvm.sdiv %105, %15 : i32
    %107 = llvm.sub %11, %106 : i32
    %108 = llvm.icmp "slt" %98, %11 : i32
    %109 = llvm.icmp "sgt" %98, %11 : i32
    %110 = llvm.and %108, %6 : i1
    %111 = llvm.and %109, %7 : i1
    %112 = llvm.or %110, %111 : i1
    %113 = llvm.select %112, %104, %107 : i1, i32
    %114 = llvm.mul %100, %14 : i64
    %115 = llvm.select %7, %8, %10 : i1, i32
    %116 = llvm.add %115, %99 : i32
    %117 = llvm.sdiv %116, %13 : i32
    %118 = llvm.add %117, %10 : i32
    %119 = llvm.sub %11, %99 : i32
    %120 = llvm.sdiv %119, %13 : i32
    %121 = llvm.sub %11, %120 : i32
    %122 = llvm.icmp "slt" %99, %11 : i32
    %123 = llvm.icmp "sgt" %99, %11 : i32
    %124 = llvm.and %122, %6 : i1
    %125 = llvm.and %123, %7 : i1
    %126 = llvm.or %124, %125 : i1
    %127 = llvm.select %126, %118, %121 : i1, i32
    %128 = llvm.insertvalue %113, %5[0] : !llvm.struct<(i32, i32)> 
    %129 = llvm.insertvalue %127, %128[1] : !llvm.struct<(i32, i32)> 
    %130 = llvm.insertvalue %100, %4[0] : !llvm.struct<(i64, i64)> 
    %131 = llvm.insertvalue %114, %130[1] : !llvm.struct<(i64, i64)> 
    %132 = llvm.insertvalue %129, %3[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %133 = llvm.insertvalue %131, %132[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %134 = llvm.insertvalue %96, %2[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %135 = llvm.insertvalue %133, %134[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)> 
    %136 = llvm.extractvalue %97[0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %137 = llvm.extractvalue %136[0] : !llvm.struct<(i32, i32)> 
    %138 = llvm.extractvalue %136[1] : !llvm.struct<(i32, i32)> 
    %139 = llvm.insertvalue %137, %5[0] : !llvm.struct<(i32, i32)> 
    %140 = llvm.insertvalue %138, %139[1] : !llvm.struct<(i32, i32)> 
    %141 = llvm.insertvalue %140, %1[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %142 = llvm.extractvalue %141[0, 0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %143 = llvm.extractvalue %141[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %144 = llvm.select %7, %8, %10 : i1, i32
    %145 = llvm.add %144, %142 : i32
    %146 = llvm.sdiv %145, %15 : i32
    %147 = llvm.add %146, %10 : i32
    %148 = llvm.sub %11, %142 : i32
    %149 = llvm.sdiv %148, %15 : i32
    %150 = llvm.sub %11, %149 : i32
    %151 = llvm.icmp "slt" %142, %11 : i32
    %152 = llvm.icmp "sgt" %142, %11 : i32
    %153 = llvm.and %151, %6 : i1
    %154 = llvm.and %152, %7 : i1
    %155 = llvm.or %153, %154 : i1
    %156 = llvm.select %155, %147, %150 : i1, i32
    %157 = llvm.select %7, %8, %10 : i1, i32
    %158 = llvm.add %157, %143 : i32
    %159 = llvm.sdiv %158, %13 : i32
    %160 = llvm.add %159, %10 : i32
    %161 = llvm.sub %11, %143 : i32
    %162 = llvm.sdiv %161, %13 : i32
    %163 = llvm.sub %11, %162 : i32
    %164 = llvm.icmp "slt" %143, %11 : i32
    %165 = llvm.icmp "sgt" %143, %11 : i32
    %166 = llvm.and %164, %6 : i1
    %167 = llvm.and %165, %7 : i1
    %168 = llvm.or %166, %167 : i1
    %169 = llvm.select %168, %160, %163 : i1, i32
    %170 = llvm.insertvalue %156, %5[0] : !llvm.struct<(i32, i32)> 
    %171 = llvm.insertvalue %169, %170[1] : !llvm.struct<(i32, i32)> 
    %172 = llvm.insertvalue %171, %1[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %173 = llvm.insertvalue %12, %172[1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %174 = llvm.insertvalue %12, %0[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %175 = llvm.insertvalue %173, %174[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %176 = llvm.mul %113, %127 : i32
    %177 = llvm.alloca %10 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %178 = llvm.alloca %10 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %179 = llvm.getelementptr %177[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %178, %179 : !llvm.ptr, !llvm.ptr
    %180 = llvm.getelementptr %177[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %13, %180 : i32, !llvm.ptr
    %181 = llvm.getelementptr %177[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %10, %181 : i32, !llvm.ptr
    %182 = llvm.getelementptr %177[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %10, %182 : i32, !llvm.ptr
    %183 = llvm.getelementptr %177[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %9, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %177[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %176, %184 : i32, !llvm.ptr
    %185 = llvm.getelementptr %177[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %10, %185 : i32, !llvm.ptr
    %186 = llvm.getelementptr %177[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %10, %186 : i32, !llvm.ptr
    %187 = llvm.getelementptr %177[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %11, %187 : i32, !llvm.ptr
    %188 = llvm.getelementptr %177[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %arg3, %188 : !llvm.ptr, !llvm.ptr
    %189 = llvm.alloca %10 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %190 = llvm.getelementptr %189[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %177, %190 : !llvm.ptr, !llvm.ptr
    %191 = builtin.unrealized_conversion_cast %189 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %192 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%191> (%55, %95, %135, %175, %137, %138) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, i32, i32) -> !cuda.result
    %193 = builtin.unrealized_conversion_cast %192 : !cuda.result to i32
    cuda.return_if_error %193 : i32
    llvm.return %11 : i32
  }
  llvm.func @_mlir_ciface_cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg3: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.ptr) -> i32
    llvm.return %0 : i32
  }
}
