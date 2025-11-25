!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %1 = llvm.mlir.constant(4 : i32) : i32
      %2 = llvm.mlir.constant(1 : i32) : i32
      %3 = llvm.alloca %1 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %4 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %5 = llvm.mlir.constant(8 : i32) : i32
      %6 = llvm.mlir.constant(1 : i32) : i32
      %7 = llvm.alloca %5 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %8 = llvm.mlir.poison : !llvm.struct<()>
      %9 = llvm.mlir.poison : !llvm.struct<()>
      %10 = llvm.mlir.poison : !llvm.struct<()>
      %11 = llvm.mlir.poison : !llvm.struct<()>
      %12 = llvm.mlir.poison : !llvm.struct<()>
      %13 = llvm.mlir.poison : !llvm.struct<()>
      %14 = llvm.mlir.constant(1 : i32) : i32
      %15 = llvm.mlir.constant(0 : i32) : i32
      %16 = llvm.mlir.poison : !llvm.struct<()>
      %17 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %18 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %19 = llvm.mlir.poison : !llvm.struct<()>
      %20 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %21 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %22 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %23 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %24 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
      %25 = llvm.extractvalue %24[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
      %26 = llvm.extractvalue %25[0] : !llvm.struct<(i32, i32, i32)> 
      %27 = llvm.extractvalue %25[1] : !llvm.struct<(i32, i32, i32)> 
      %28 = llvm.extractvalue %25[2] : !llvm.struct<(i32, i32, i32)> 
      %29 = llvm.extractvalue %24[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
      %30 = llvm.extractvalue %29[0] : !llvm.struct<(i64, i64)> 
      %31 = llvm.extractvalue %29[1] : !llvm.struct<(i64, i64)> 
      %32 = llvm.sdiv %23, %26 : i32
      %33 = llvm.srem %23, %26 : i32
      %34 = llvm.mlir.constant(1024 : i32) : i32
      %35 = llvm.mul %33, %34 : i32
      %36 = llvm.sdiv %32, %27 : i32
      %37 = llvm.srem %32, %27 : i32
      %38 = llvm.sext %37 : i32 to i64
      %39 = llvm.mul %38, %30 : i64
      %40 = llvm.sext %35 : i32 to i64
      %41 = llvm.add %40, %39 : i64
      %42 = llvm.sext %36 : i32 to i64
      %43 = llvm.mul %42, %31 : i64
      %44 = llvm.add %41, %43 : i64
      %45 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
      %46 = llvm.getelementptr %45[%44] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %47 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
      %48 = llvm.extractvalue %47[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
      %49 = llvm.extractvalue %48[0] : !llvm.struct<(i32, i32, i32)> 
      %50 = llvm.extractvalue %48[1] : !llvm.struct<(i32, i32, i32)> 
      %51 = llvm.extractvalue %48[2] : !llvm.struct<(i32, i32, i32)> 
      %52 = llvm.extractvalue %47[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
      %53 = llvm.extractvalue %52[0] : !llvm.struct<(i64, i64)> 
      %54 = llvm.extractvalue %52[1] : !llvm.struct<(i64, i64)> 
      %55 = llvm.sdiv %23, %49 : i32
      %56 = llvm.srem %23, %49 : i32
      %57 = llvm.mlir.constant(512 : i32) : i32
      %58 = llvm.mul %56, %57 : i32
      %59 = llvm.sdiv %55, %50 : i32
      %60 = llvm.srem %55, %50 : i32
      %61 = llvm.sext %60 : i32 to i64
      %62 = llvm.mul %61, %53 : i64
      %63 = llvm.sext %58 : i32 to i64
      %64 = llvm.add %63, %62 : i64
      %65 = llvm.sext %59 : i32 to i64
      %66 = llvm.mul %65, %54 : i64
      %67 = llvm.add %64, %66 : i64
      %68 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
      %69 = llvm.getelementptr %68[%67] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, i8
      %70 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
      %71 = llvm.extractvalue %70[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
      %72 = llvm.extractvalue %71[0] : !llvm.struct<(i32, i32, i32)> 
      %73 = llvm.extractvalue %71[1] : !llvm.struct<(i32, i32, i32)> 
      %74 = llvm.extractvalue %71[2] : !llvm.struct<(i32, i32, i32)> 
      %75 = llvm.extractvalue %70[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
      %76 = llvm.sdiv %23, %72 : i32
      %77 = llvm.srem %23, %72 : i32
      %78 = llvm.mlir.constant(1024 : i32) : i32
      %79 = llvm.mul %77, %78 : i32
      %80 = llvm.sdiv %76, %73 : i32
      %81 = llvm.srem %76, %73 : i32
      %82 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %83 = llvm.insertvalue %79, %82[0] : !llvm.struct<(i32, i32, i32)> 
      %84 = llvm.insertvalue %81, %83[1] : !llvm.struct<(i32, i32, i32)> 
      %85 = llvm.insertvalue %80, %84[2] : !llvm.struct<(i32, i32, i32)> 
      %86 = llvm.extractvalue %85[0] : !llvm.struct<(i32, i32, i32)> 
      %87 = llvm.extractvalue %85[1] : !llvm.struct<(i32, i32, i32)> 
      %88 = llvm.extractvalue %85[2] : !llvm.struct<(i32, i32, i32)> 
      %89 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %90 = llvm.insertvalue %86, %89[0] : !llvm.struct<(i32, i32, i32)> 
      %91 = llvm.insertvalue %87, %90[1] : !llvm.struct<(i32, i32, i32)> 
      %92 = llvm.insertvalue %88, %91[2] : !llvm.struct<(i32, i32, i32)> 
      %93 = llvm.extractvalue %20[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %94 = llvm.extractvalue %20[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %95 = llvm.mlir.constant(8 : i32) : i32
      %96 = llvm.mul %22, %95 : i32
      %97 = llvm.getelementptr %46[%96] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %98 = builtin.unrealized_conversion_cast %97 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %99 = llvm.extractvalue %21[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %100 = llvm.extractvalue %21[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %101 = llvm.mlir.constant(4 : i32) : i32
      %102 = llvm.mul %22, %101 : i32
      %103 = llvm.getelementptr %69[%102] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %104 = builtin.unrealized_conversion_cast %103 : !llvm.ptr<1> to !cute.ptr<i8, gmem>
      %105 = llvm.extractvalue %18[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %106 = llvm.extractvalue %18[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %107 = llvm.mlir.constant(8 : i32) : i32
      %108 = llvm.mul %22, %107 : i32
      %109 = llvm.extractvalue %92[0] : !llvm.struct<(i32, i32, i32)> 
      %110 = llvm.extractvalue %92[1] : !llvm.struct<(i32, i32, i32)> 
      %111 = llvm.extractvalue %92[2] : !llvm.struct<(i32, i32, i32)> 
      %112 = llvm.add %109, %108 : i32
      %113 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %114 = llvm.insertvalue %112, %113[0] : !llvm.struct<(i32, i32, i32)> 
      %115 = llvm.insertvalue %110, %114[1] : !llvm.struct<(i32, i32, i32)> 
      %116 = llvm.insertvalue %111, %115[2] : !llvm.struct<(i32, i32, i32)> 
      %117 = llvm.extractvalue %116[0] : !llvm.struct<(i32, i32, i32)> 
      %118 = llvm.extractvalue %116[1] : !llvm.struct<(i32, i32, i32)> 
      %119 = llvm.extractvalue %116[2] : !llvm.struct<(i32, i32, i32)> 
      %120 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %121 = llvm.insertvalue %117, %120[0] : !llvm.struct<(i32, i32, i32)> 
      %122 = llvm.insertvalue %118, %121[1] : !llvm.struct<(i32, i32, i32)> 
      %123 = llvm.insertvalue %119, %122[2] : !llvm.struct<(i32, i32, i32)> 
      %124 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %125 = llvm.insertvalue %arg3, %124[0] : !llvm.struct<(i32, i32, i32)> 
      %126 = llvm.insertvalue %arg4, %125[1] : !llvm.struct<(i32, i32, i32)> 
      %127 = llvm.insertvalue %arg5, %126[2] : !llvm.struct<(i32, i32, i32)> 
      %128 = llvm.extractvalue %123[0] : !llvm.struct<(i32, i32, i32)> 
      %129 = llvm.extractvalue %123[1] : !llvm.struct<(i32, i32, i32)> 
      %130 = llvm.extractvalue %123[2] : !llvm.struct<(i32, i32, i32)> 
      %131 = llvm.extractvalue %127[0] : !llvm.struct<(i32, i32, i32)> 
      %132 = llvm.extractvalue %127[1] : !llvm.struct<(i32, i32, i32)> 
      %133 = llvm.extractvalue %127[2] : !llvm.struct<(i32, i32, i32)> 
      %134 = llvm.icmp "slt" %128, %131 : i32
      %135 = llvm.icmp "slt" %129, %132 : i32
      %136 = llvm.and %134, %135 : i1
      %137 = llvm.icmp "slt" %130, %133 : i32
      %138 = llvm.and %136, %137 : i1
      llvm.cond_br %138, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %139 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %140 = llvm.insertvalue %7, %139[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %141 = llvm.insertvalue %4, %140[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %142 = llvm.extractvalue %141[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %143 = builtin.unrealized_conversion_cast %142 : !llvm.ptr to !cute.ptr<f32, rmem, align<32>>
      %144 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %145 = llvm.insertvalue %3, %144[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %146 = llvm.insertvalue %0, %145[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %147 = llvm.extractvalue %146[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %148 = builtin.unrealized_conversion_cast %147 : !llvm.ptr to !cute.ptr<i8, rmem, align<32>>
      %149 = llvm.mlir.constant(1 : i32) : i32
      %150 = builtin.unrealized_conversion_cast %98 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %151 = builtin.unrealized_conversion_cast %143 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %152 = llvm.mlir.constant(1 : i32) : i32
      %153 = llvm.getelementptr %97[%152] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %154 = builtin.unrealized_conversion_cast %153 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %155 = llvm.mlir.constant(1 : i32) : i32
      %156 = llvm.getelementptr %142[%155] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %157 = builtin.unrealized_conversion_cast %156 : !llvm.ptr to !cute.ptr<f32, rmem>
      %158 = builtin.unrealized_conversion_cast %154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %159 = builtin.unrealized_conversion_cast %157 : !cute.ptr<f32, rmem> to !llvm.ptr
      %160 = llvm.mlir.constant(2 : i32) : i32
      %161 = llvm.getelementptr %97[%160] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %162 = builtin.unrealized_conversion_cast %161 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %163 = llvm.mlir.constant(2 : i32) : i32
      %164 = llvm.getelementptr %142[%163] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %165 = builtin.unrealized_conversion_cast %164 : !llvm.ptr to !cute.ptr<f32, rmem, align<8>>
      %166 = builtin.unrealized_conversion_cast %162 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %167 = builtin.unrealized_conversion_cast %165 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %168 = llvm.mlir.constant(3 : i32) : i32
      %169 = llvm.getelementptr %97[%168] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %170 = builtin.unrealized_conversion_cast %169 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %171 = llvm.mlir.constant(3 : i32) : i32
      %172 = llvm.getelementptr %142[%171] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %173 = builtin.unrealized_conversion_cast %172 : !llvm.ptr to !cute.ptr<f32, rmem>
      %174 = builtin.unrealized_conversion_cast %170 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %175 = builtin.unrealized_conversion_cast %173 : !cute.ptr<f32, rmem> to !llvm.ptr
      %176 = llvm.mlir.constant(4 : i32) : i32
      %177 = llvm.getelementptr %97[%176] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %178 = builtin.unrealized_conversion_cast %177 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %179 = llvm.mlir.constant(4 : i32) : i32
      %180 = llvm.getelementptr %142[%179] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %181 = builtin.unrealized_conversion_cast %180 : !llvm.ptr to !cute.ptr<f32, rmem, align<16>>
      %182 = builtin.unrealized_conversion_cast %178 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %183 = builtin.unrealized_conversion_cast %181 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %184 = llvm.mlir.constant(5 : i32) : i32
      %185 = llvm.getelementptr %97[%184] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %186 = builtin.unrealized_conversion_cast %185 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %187 = llvm.mlir.constant(5 : i32) : i32
      %188 = llvm.getelementptr %142[%187] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %189 = builtin.unrealized_conversion_cast %188 : !llvm.ptr to !cute.ptr<f32, rmem>
      %190 = builtin.unrealized_conversion_cast %186 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %191 = builtin.unrealized_conversion_cast %189 : !cute.ptr<f32, rmem> to !llvm.ptr
      %192 = llvm.mlir.constant(6 : i32) : i32
      %193 = llvm.getelementptr %97[%192] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %194 = builtin.unrealized_conversion_cast %193 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %195 = llvm.mlir.constant(6 : i32) : i32
      %196 = llvm.getelementptr %142[%195] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %197 = builtin.unrealized_conversion_cast %196 : !llvm.ptr to !cute.ptr<f32, rmem, align<8>>
      %198 = builtin.unrealized_conversion_cast %194 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %199 = builtin.unrealized_conversion_cast %197 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %200 = llvm.mlir.constant(7 : i32) : i32
      %201 = llvm.getelementptr %97[%200] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %202 = builtin.unrealized_conversion_cast %201 : !llvm.ptr<1> to !cute.ptr<f32, gmem>
      %203 = llvm.mlir.constant(7 : i32) : i32
      %204 = llvm.getelementptr %142[%203] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %205 = builtin.unrealized_conversion_cast %204 : !llvm.ptr to !cute.ptr<f32, rmem>
      %206 = builtin.unrealized_conversion_cast %202 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %207 = builtin.unrealized_conversion_cast %205 : !cute.ptr<f32, rmem> to !llvm.ptr
      llvm.br ^bb2(%15 : i32)
    ^bb2(%208: i32):  // 2 preds: ^bb1, ^bb3
      %209 = llvm.icmp "slt" %208, %149 : i32
      llvm.cond_br %209, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %210 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %210, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %211 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %211, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %212 = llvm.load %166 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %212, %167 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %213 = llvm.load %174 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %213, %175 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %214 = llvm.load %182 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %214, %183 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %215 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %215, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %216 = llvm.load %198 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %216, %199 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %217 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %217, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %218 = llvm.add %208, %14 : i32
      llvm.br ^bb2(%218 : i32)
    ^bb4:  // pred: ^bb2
      %219 = llvm.mlir.poison : !llvm.array<1 x vector<8xf32>>
      %220 = builtin.unrealized_conversion_cast %219 : !llvm.array<1 x vector<8xf32>> to vector<1x8xf32>
      %221 = llvm.extractvalue %141[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %222 = llvm.getelementptr %221[0] : (!llvm.ptr) -> !llvm.ptr, f32
      %223 = llvm.load %222 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
      %224 = vector.insert %223, %220 [0] : vector<8xf32> into vector<1x8xf32>
      %225 = vector.shape_cast %224 : vector<1x8xf32> to vector<8xf32>
      %226 = vector.shuffle %225, %225 [0, 1, 2, 3, 4, 5, 6, 7] : vector<8xf32>, vector<8xf32>
      %227 = llvm.fptosi %226 : vector<8xf32> to vector<8xi4>
      %228 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %229 = vector.bitcast %227 : vector<8xi4> to vector<4xi8>
      %230 = vector.shuffle %229, %229 [0, 1, 2, 3] : vector<4xi8>, vector<4xi8>
      %231 = vector.shape_cast %230 : vector<4xi8> to vector<1x4xi8>
      %232 = llvm.extractvalue %146[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %233 = vector.extract %231[0] : vector<4xi8> from vector<1x4xi8>
      %234 = llvm.getelementptr %232[0] : (!llvm.ptr) -> !llvm.ptr, i8
      llvm.store %233, %234 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
      %235 = builtin.unrealized_conversion_cast %148 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %236 = builtin.unrealized_conversion_cast %104 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %237 = llvm.mlir.constant(1 : i32) : i32
      %238 = llvm.getelementptr %147[%237] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %239 = builtin.unrealized_conversion_cast %238 : !llvm.ptr to !cute.ptr<i8, rmem>
      %240 = llvm.mlir.constant(1 : i32) : i32
      %241 = llvm.getelementptr %103[%240] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %242 = builtin.unrealized_conversion_cast %241 : !llvm.ptr<1> to !cute.ptr<i8, gmem>
      %243 = builtin.unrealized_conversion_cast %239 : !cute.ptr<i8, rmem> to !llvm.ptr
      %244 = builtin.unrealized_conversion_cast %242 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %245 = llvm.mlir.constant(2 : i32) : i32
      %246 = llvm.getelementptr %147[%245] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %247 = builtin.unrealized_conversion_cast %246 : !llvm.ptr to !cute.ptr<i8, rmem, align<2>>
      %248 = llvm.mlir.constant(2 : i32) : i32
      %249 = llvm.getelementptr %103[%248] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %250 = builtin.unrealized_conversion_cast %249 : !llvm.ptr<1> to !cute.ptr<i8, gmem>
      %251 = builtin.unrealized_conversion_cast %247 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %252 = builtin.unrealized_conversion_cast %250 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %253 = llvm.mlir.constant(3 : i32) : i32
      %254 = llvm.getelementptr %147[%253] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %255 = builtin.unrealized_conversion_cast %254 : !llvm.ptr to !cute.ptr<i8, rmem>
      %256 = llvm.mlir.constant(3 : i32) : i32
      %257 = llvm.getelementptr %103[%256] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %258 = builtin.unrealized_conversion_cast %257 : !llvm.ptr<1> to !cute.ptr<i8, gmem>
      %259 = builtin.unrealized_conversion_cast %255 : !cute.ptr<i8, rmem> to !llvm.ptr
      %260 = builtin.unrealized_conversion_cast %258 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      llvm.br ^bb5(%15 : i32)
    ^bb5(%261: i32):  // 2 preds: ^bb4, ^bb6
      %262 = llvm.icmp "slt" %261, %149 : i32
      llvm.cond_br %262, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %263 = llvm.load %235 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %263, %236 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %264 = llvm.load %243 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %264, %244 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %265 = llvm.load %251 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %265, %252 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %266 = llvm.load %259 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %266, %260 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %267 = llvm.add %261, %14 : i32
      llvm.br ^bb5(%267 : i32)
    ^bb7:  // pred: ^bb5
      llvm.br ^bb8
    ^bb8:  // 2 preds: ^bb0, ^bb7
      llvm.return
    }
  }
  llvm.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(128 : index) : i64
    %2 = builtin.unrealized_conversion_cast %1 : i64 to index
    %3 = llvm.mlir.constant(1 : index) : i64
    %4 = builtin.unrealized_conversion_cast %3 : i64 to index
    %5 = llvm.mlir.constant(512 : i32) : i32
    %6 = llvm.mlir.poison : !llvm.struct<()>
    %7 = llvm.mlir.constant(1024 : i32) : i32
    %8 = llvm.mlir.poison : !llvm.struct<()>
    %9 = llvm.mlir.poison : !llvm.struct<()>
    %10 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
    %11 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %12 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
    %13 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %14 = llvm.extractvalue %13[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %15 = llvm.extractvalue %13[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %16 = llvm.extractvalue %13[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %17 = llvm.extractvalue %13[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %18 = llvm.extractvalue %13[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %19 = llvm.mlir.constant(2 : i32) : i32
    %20 = llvm.mlir.constant(1 : i32) : i32
    %21 = llvm.mlir.constant(0 : i32) : i32
    %22 = llvm.mlir.constant(-1 : i32) : i32
    %23 = llvm.mlir.constant(true) : i1
    %24 = llvm.select %23, %22, %20 : i1, i32
    %25 = llvm.add %24, %14 : i32
    %26 = llvm.sdiv %25, %19 : i32
    %27 = llvm.add %26, %20 : i32
    %28 = llvm.sub %21, %14 : i32
    %29 = llvm.sdiv %28, %19 : i32
    %30 = llvm.sub %21, %29 : i32
    %31 = llvm.icmp "slt" %14, %21 : i32
    %32 = llvm.icmp "sgt" %14, %21 : i32
    %33 = llvm.mlir.constant(false) : i1
    %34 = llvm.mlir.constant(true) : i1
    %35 = llvm.and %31, %33 : i1
    %36 = llvm.and %32, %34 : i1
    %37 = llvm.or %35, %36 : i1
    %38 = llvm.select %37, %27, %30 : i1, i32
    %39 = llvm.mlir.constant(2 : i64) : i64
    %40 = llvm.sdiv %17, %39 : i64
    %41 = llvm.mlir.constant(0 : i64) : i64
    %42 = llvm.icmp "ne" %40, %41 : i64
    %43 = scf.if %42 -> (i64) {
      scf.yield %40 : i64
    } else {
      %189 = llvm.mlir.constant(0 : i64) : i64
      %190 = llvm.icmp "sgt" %17, %189 : i64
      %191 = scf.if %190 -> (i32) {
        %193 = llvm.mlir.constant(1 : i32) : i32
        scf.yield %193 : i32
      } else {
        %193 = llvm.mlir.constant(0 : i64) : i64
        %194 = llvm.icmp "eq" %17, %193 : i64
        %195 = scf.if %194 -> (i32) {
          %196 = llvm.mlir.constant(0 : i32) : i32
          scf.yield %196 : i32
        } else {
          %196 = llvm.mlir.constant(-1 : i32) : i32
          scf.yield %196 : i32
        }
        scf.yield %195 : i32
      }
      %192 = llvm.sext %191 : i32 to i64
      scf.yield %192 : i64
    }
    %44 = llvm.mlir.constant(2 : i64) : i64
    %45 = llvm.sdiv %18, %44 : i64
    %46 = llvm.mlir.constant(0 : i64) : i64
    %47 = llvm.icmp "ne" %45, %46 : i64
    %48 = scf.if %47 -> (i64) {
      scf.yield %45 : i64
    } else {
      %189 = llvm.mlir.constant(0 : i64) : i64
      %190 = llvm.icmp "sgt" %18, %189 : i64
      %191 = scf.if %190 -> (i32) {
        %193 = llvm.mlir.constant(1 : i32) : i32
        scf.yield %193 : i32
      } else {
        %193 = llvm.mlir.constant(0 : i64) : i64
        %194 = llvm.icmp "eq" %18, %193 : i64
        %195 = scf.if %194 -> (i32) {
          %196 = llvm.mlir.constant(0 : i32) : i32
          scf.yield %196 : i32
        } else {
          %196 = llvm.mlir.constant(-1 : i32) : i32
          scf.yield %196 : i32
        }
        scf.yield %195 : i32
      }
      %192 = llvm.sext %191 : i32 to i64
      scf.yield %192 : i64
    }
    %49 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %50 = llvm.insertvalue %38, %49[0] : !llvm.struct<(i32, i32, i32)> 
    %51 = llvm.insertvalue %15, %50[1] : !llvm.struct<(i32, i32, i32)> 
    %52 = llvm.insertvalue %16, %51[2] : !llvm.struct<(i32, i32, i32)> 
    %53 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %54 = llvm.insertvalue %43, %53[0] : !llvm.struct<(i64, i64)> 
    %55 = llvm.insertvalue %48, %54[1] : !llvm.struct<(i64, i64)> 
    %56 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %57 = llvm.insertvalue %52, %56[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %58 = llvm.insertvalue %55, %57[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %59 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %60 = llvm.extractvalue %59[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %61 = llvm.extractvalue %60[0] : !llvm.struct<(i32, i32, i32)> 
    %62 = llvm.extractvalue %60[1] : !llvm.struct<(i32, i32, i32)> 
    %63 = llvm.extractvalue %60[2] : !llvm.struct<(i32, i32, i32)> 
    %64 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %65 = llvm.insertvalue %61, %64[0] : !llvm.struct<(i32, i32, i32)> 
    %66 = llvm.insertvalue %62, %65[1] : !llvm.struct<(i32, i32, i32)> 
    %67 = llvm.insertvalue %63, %66[2] : !llvm.struct<(i32, i32, i32)> 
    %68 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %69 = llvm.insertvalue %67, %68[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %70 = llvm.insertvalue %8, %69[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %71 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %72 = llvm.extractvalue %59[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %73 = llvm.extractvalue %59[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %74 = llvm.extractvalue %59[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %75 = llvm.extractvalue %59[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %76 = llvm.extractvalue %59[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %77 = llvm.mlir.constant(1 : i32) : i32
    %78 = llvm.mlir.constant(0 : i32) : i32
    %79 = llvm.mlir.constant(-1 : i32) : i32
    %80 = llvm.mlir.constant(true) : i1
    %81 = llvm.select %80, %79, %77 : i1, i32
    %82 = llvm.add %81, %72 : i32
    %83 = llvm.sdiv %82, %7 : i32
    %84 = llvm.add %83, %77 : i32
    %85 = llvm.sub %78, %72 : i32
    %86 = llvm.sdiv %85, %7 : i32
    %87 = llvm.sub %78, %86 : i32
    %88 = llvm.icmp "slt" %72, %78 : i32
    %89 = llvm.icmp "sgt" %72, %78 : i32
    %90 = llvm.mlir.constant(false) : i1
    %91 = llvm.mlir.constant(true) : i1
    %92 = llvm.and %88, %90 : i1
    %93 = llvm.and %89, %91 : i1
    %94 = llvm.or %92, %93 : i1
    %95 = llvm.select %94, %84, %87 : i1, i32
    %96 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %97 = llvm.insertvalue %95, %96[0] : !llvm.struct<(i32, i32, i32)> 
    %98 = llvm.insertvalue %73, %97[1] : !llvm.struct<(i32, i32, i32)> 
    %99 = llvm.insertvalue %74, %98[2] : !llvm.struct<(i32, i32, i32)> 
    %100 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %101 = llvm.insertvalue %75, %100[0] : !llvm.struct<(i64, i64)> 
    %102 = llvm.insertvalue %76, %101[1] : !llvm.struct<(i64, i64)> 
    %103 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %104 = llvm.insertvalue %99, %103[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %105 = llvm.insertvalue %102, %104[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %106 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %107 = llvm.insertvalue %71, %106[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %108 = llvm.insertvalue %105, %107[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %109 = builtin.unrealized_conversion_cast %108 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_f32_
    %110 = llvm.extractvalue %70[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %111 = llvm.extractvalue %70[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %112 = llvm.extractvalue %70[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %113 = llvm.mlir.constant(1 : i32) : i32
    %114 = llvm.mlir.constant(0 : i32) : i32
    %115 = llvm.mlir.constant(-1 : i32) : i32
    %116 = llvm.mlir.constant(true) : i1
    %117 = llvm.select %116, %115, %113 : i1, i32
    %118 = llvm.add %117, %110 : i32
    %119 = llvm.sdiv %118, %7 : i32
    %120 = llvm.add %119, %113 : i32
    %121 = llvm.sub %114, %110 : i32
    %122 = llvm.sdiv %121, %7 : i32
    %123 = llvm.sub %114, %122 : i32
    %124 = llvm.icmp "slt" %110, %114 : i32
    %125 = llvm.icmp "sgt" %110, %114 : i32
    %126 = llvm.mlir.constant(false) : i1
    %127 = llvm.mlir.constant(true) : i1
    %128 = llvm.and %124, %126 : i1
    %129 = llvm.and %125, %127 : i1
    %130 = llvm.or %128, %129 : i1
    %131 = llvm.select %130, %120, %123 : i1, i32
    %132 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %133 = llvm.insertvalue %131, %132[0] : !llvm.struct<(i32, i32, i32)> 
    %134 = llvm.insertvalue %111, %133[1] : !llvm.struct<(i32, i32, i32)> 
    %135 = llvm.insertvalue %112, %134[2] : !llvm.struct<(i32, i32, i32)> 
    %136 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %137 = llvm.insertvalue %135, %136[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %138 = llvm.insertvalue %6, %137[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %139 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>
    %140 = llvm.insertvalue %9, %139[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %141 = llvm.insertvalue %138, %140[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %142 = builtin.unrealized_conversion_cast %141 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %143 = llvm.extractvalue %58[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %144 = llvm.extractvalue %58[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %145 = llvm.extractvalue %58[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %146 = llvm.extractvalue %58[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %147 = llvm.extractvalue %58[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %148 = llvm.mlir.constant(1 : i32) : i32
    %149 = llvm.mlir.constant(0 : i32) : i32
    %150 = llvm.mlir.constant(-1 : i32) : i32
    %151 = llvm.mlir.constant(true) : i1
    %152 = llvm.select %151, %150, %148 : i1, i32
    %153 = llvm.add %152, %143 : i32
    %154 = llvm.sdiv %153, %5 : i32
    %155 = llvm.add %154, %148 : i32
    %156 = llvm.sub %149, %143 : i32
    %157 = llvm.sdiv %156, %5 : i32
    %158 = llvm.sub %149, %157 : i32
    %159 = llvm.icmp "slt" %143, %149 : i32
    %160 = llvm.icmp "sgt" %143, %149 : i32
    %161 = llvm.mlir.constant(false) : i1
    %162 = llvm.mlir.constant(true) : i1
    %163 = llvm.and %159, %161 : i1
    %164 = llvm.and %160, %162 : i1
    %165 = llvm.or %163, %164 : i1
    %166 = llvm.select %165, %155, %158 : i1, i32
    %167 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %168 = llvm.insertvalue %166, %167[0] : !llvm.struct<(i32, i32, i32)> 
    %169 = llvm.insertvalue %144, %168[1] : !llvm.struct<(i32, i32, i32)> 
    %170 = llvm.insertvalue %145, %169[2] : !llvm.struct<(i32, i32, i32)> 
    %171 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %172 = llvm.insertvalue %146, %171[0] : !llvm.struct<(i64, i64)> 
    %173 = llvm.insertvalue %147, %172[1] : !llvm.struct<(i64, i64)> 
    %174 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %175 = llvm.insertvalue %170, %174[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %176 = llvm.insertvalue %173, %175[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %177 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %178 = llvm.insertvalue %11, %177[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %179 = llvm.insertvalue %176, %178[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %180 = builtin.unrealized_conversion_cast %179 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_i8_
    %181 = llvm.extractvalue %105[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %182 = llvm.extractvalue %181[0] : !llvm.struct<(i32, i32, i32)> 
    %183 = llvm.extractvalue %181[1] : !llvm.struct<(i32, i32, i32)> 
    %184 = llvm.extractvalue %181[2] : !llvm.struct<(i32, i32, i32)> 
    %185 = llvm.mul %182, %183 : i32
    %186 = llvm.mul %185, %184 : i32
    %187 = llvm.sext %186 : i32 to i64
    %188 = builtin.unrealized_conversion_cast %187 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%188, %4, %4) threads in (%2, %4, %4)  dynamic_shared_memory_size %0 args(%109 : !memref_gmem_f32_, %180 : !memref_gmem_i8_, %142 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %61 : i32, %62 : i32, %63 : i32) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> ()
    llvm.return
  }
}
