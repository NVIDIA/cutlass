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
      %98 = llvm.extractvalue %21[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %99 = llvm.extractvalue %21[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %100 = llvm.mlir.constant(4 : i32) : i32
      %101 = llvm.mul %22, %100 : i32
      %102 = llvm.getelementptr %69[%101] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %103 = llvm.extractvalue %18[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %104 = llvm.extractvalue %18[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %105 = llvm.mlir.constant(8 : i32) : i32
      %106 = llvm.mul %22, %105 : i32
      %107 = llvm.extractvalue %92[0] : !llvm.struct<(i32, i32, i32)> 
      %108 = llvm.extractvalue %92[1] : !llvm.struct<(i32, i32, i32)> 
      %109 = llvm.extractvalue %92[2] : !llvm.struct<(i32, i32, i32)> 
      %110 = llvm.add %107, %106 : i32
      %111 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %112 = llvm.insertvalue %110, %111[0] : !llvm.struct<(i32, i32, i32)> 
      %113 = llvm.insertvalue %108, %112[1] : !llvm.struct<(i32, i32, i32)> 
      %114 = llvm.insertvalue %109, %113[2] : !llvm.struct<(i32, i32, i32)> 
      %115 = llvm.extractvalue %114[0] : !llvm.struct<(i32, i32, i32)> 
      %116 = llvm.extractvalue %114[1] : !llvm.struct<(i32, i32, i32)> 
      %117 = llvm.extractvalue %114[2] : !llvm.struct<(i32, i32, i32)> 
      %118 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %119 = llvm.insertvalue %115, %118[0] : !llvm.struct<(i32, i32, i32)> 
      %120 = llvm.insertvalue %116, %119[1] : !llvm.struct<(i32, i32, i32)> 
      %121 = llvm.insertvalue %117, %120[2] : !llvm.struct<(i32, i32, i32)> 
      %122 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
      %123 = llvm.insertvalue %arg3, %122[0] : !llvm.struct<(i32, i32, i32)> 
      %124 = llvm.insertvalue %arg4, %123[1] : !llvm.struct<(i32, i32, i32)> 
      %125 = llvm.insertvalue %arg5, %124[2] : !llvm.struct<(i32, i32, i32)> 
      %126 = llvm.extractvalue %121[0] : !llvm.struct<(i32, i32, i32)> 
      %127 = llvm.extractvalue %121[1] : !llvm.struct<(i32, i32, i32)> 
      %128 = llvm.extractvalue %121[2] : !llvm.struct<(i32, i32, i32)> 
      %129 = llvm.extractvalue %125[0] : !llvm.struct<(i32, i32, i32)> 
      %130 = llvm.extractvalue %125[1] : !llvm.struct<(i32, i32, i32)> 
      %131 = llvm.extractvalue %125[2] : !llvm.struct<(i32, i32, i32)> 
      %132 = llvm.icmp "slt" %126, %129 : i32
      %133 = llvm.icmp "slt" %127, %130 : i32
      %134 = llvm.and %132, %133 : i1
      %135 = llvm.icmp "slt" %128, %131 : i32
      %136 = llvm.and %134, %135 : i1
      llvm.cond_br %136, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %137 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %138 = llvm.insertvalue %7, %137[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %139 = llvm.insertvalue %4, %138[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %140 = llvm.extractvalue %139[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %141 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %142 = llvm.insertvalue %3, %141[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %143 = llvm.insertvalue %0, %142[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %144 = llvm.extractvalue %143[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %145 = llvm.mlir.constant(1 : i32) : i32
      %146 = llvm.mlir.constant(1 : i32) : i32
      %147 = llvm.getelementptr %97[%146] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %148 = llvm.mlir.constant(1 : i32) : i32
      %149 = llvm.getelementptr %140[%148] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %150 = llvm.mlir.constant(2 : i32) : i32
      %151 = llvm.getelementptr %97[%150] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %152 = llvm.mlir.constant(2 : i32) : i32
      %153 = llvm.getelementptr %140[%152] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %154 = llvm.mlir.constant(3 : i32) : i32
      %155 = llvm.getelementptr %97[%154] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %156 = llvm.mlir.constant(3 : i32) : i32
      %157 = llvm.getelementptr %140[%156] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %158 = llvm.mlir.constant(4 : i32) : i32
      %159 = llvm.getelementptr %97[%158] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %160 = llvm.mlir.constant(4 : i32) : i32
      %161 = llvm.getelementptr %140[%160] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %162 = llvm.mlir.constant(5 : i32) : i32
      %163 = llvm.getelementptr %97[%162] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %164 = llvm.mlir.constant(5 : i32) : i32
      %165 = llvm.getelementptr %140[%164] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %166 = llvm.mlir.constant(6 : i32) : i32
      %167 = llvm.getelementptr %97[%166] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %168 = llvm.mlir.constant(6 : i32) : i32
      %169 = llvm.getelementptr %140[%168] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      %170 = llvm.mlir.constant(7 : i32) : i32
      %171 = llvm.getelementptr %97[%170] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
      %172 = llvm.mlir.constant(7 : i32) : i32
      %173 = llvm.getelementptr %140[%172] : (!llvm.ptr, i32) -> !llvm.ptr, f32
      llvm.br ^bb2(%15 : i32)
    ^bb2(%174: i32):  // 2 preds: ^bb1, ^bb3
      %175 = llvm.icmp "slt" %174, %145 : i32
      llvm.cond_br %175, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %176 = llvm.load %97 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %176, %140 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %177 = llvm.load %147 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %177, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %178 = llvm.load %151 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %178, %153 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %179 = llvm.load %155 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %179, %157 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %180 = llvm.load %159 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %180, %161 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %181 = llvm.load %163 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %181, %165 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %182 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %182, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %183 = llvm.load %171 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %183, %173 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %184 = llvm.add %174, %14 : i32
      llvm.br ^bb2(%184 : i32)
    ^bb4:  // pred: ^bb2
      %185 = llvm.mlir.poison : !llvm.array<1 x vector<8xf32>>
      %186 = builtin.unrealized_conversion_cast %185 : !llvm.array<1 x vector<8xf32>> to vector<1x8xf32>
      %187 = llvm.extractvalue %139[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %188 = llvm.getelementptr %187[0] : (!llvm.ptr) -> !llvm.ptr, f32
      %189 = llvm.load %188 {alignment = 32 : i64} : !llvm.ptr -> vector<8xf32>
      %190 = vector.insert %189, %186 [0] : vector<8xf32> into vector<1x8xf32>
      %191 = vector.shape_cast %190 : vector<1x8xf32> to vector<8xf32>
      %192 = vector.shuffle %191, %191 [0, 1, 2, 3, 4, 5, 6, 7] : vector<8xf32>, vector<8xf32>
      %193 = llvm.fptosi %192 : vector<8xf32> to vector<8xi4>
      %194 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %195 = vector.bitcast %193 : vector<8xi4> to vector<4xi8>
      %196 = vector.shuffle %195, %195 [0, 1, 2, 3] : vector<4xi8>, vector<4xi8>
      %197 = vector.shape_cast %196 : vector<4xi8> to vector<1x4xi8>
      %198 = llvm.extractvalue %143[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %199 = vector.extract %197[0] : vector<4xi8> from vector<1x4xi8>
      %200 = llvm.getelementptr %198[0] : (!llvm.ptr) -> !llvm.ptr, i8
      llvm.store %199, %200 {alignment = 32 : i64} : vector<4xi8>, !llvm.ptr
      %201 = llvm.mlir.constant(1 : i32) : i32
      %202 = llvm.getelementptr %144[%201] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %203 = llvm.mlir.constant(1 : i32) : i32
      %204 = llvm.getelementptr %102[%203] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %205 = llvm.mlir.constant(2 : i32) : i32
      %206 = llvm.getelementptr %144[%205] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %207 = llvm.mlir.constant(2 : i32) : i32
      %208 = llvm.getelementptr %102[%207] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %209 = llvm.mlir.constant(3 : i32) : i32
      %210 = llvm.getelementptr %144[%209] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %211 = llvm.mlir.constant(3 : i32) : i32
      %212 = llvm.getelementptr %102[%211] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      llvm.br ^bb5(%15 : i32)
    ^bb5(%213: i32):  // 2 preds: ^bb4, ^bb6
      %214 = llvm.icmp "slt" %213, %145 : i32
      llvm.cond_br %214, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %215 = llvm.load %144 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %215, %102 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %216 = llvm.load %202 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %216, %204 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %217 = llvm.load %206 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %217, %208 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %218 = llvm.load %210 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %218, %212 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %219 = llvm.add %213, %14 : i32
      llvm.br ^bb5(%219 : i32)
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
