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
    cf.cond_br %42, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    cf.br ^bb11(%40 : i64)
  ^bb2:  // pred: ^bb0
    %43 = llvm.mlir.constant(0 : i64) : i64
    %44 = llvm.icmp "sgt" %17, %43 : i64
    cf.cond_br %44, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    %45 = llvm.mlir.constant(1 : i32) : i32
    cf.br ^bb9(%45 : i32)
  ^bb4:  // pred: ^bb2
    %46 = llvm.mlir.constant(0 : i64) : i64
    %47 = llvm.icmp "eq" %17, %46 : i64
    cf.cond_br %47, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    %48 = llvm.mlir.constant(0 : i32) : i32
    cf.br ^bb7(%48 : i32)
  ^bb6:  // pred: ^bb4
    %49 = llvm.mlir.constant(-1 : i32) : i32
    cf.br ^bb7(%49 : i32)
  ^bb7(%50: i32):  // 2 preds: ^bb5, ^bb6
    cf.br ^bb8
  ^bb8:  // pred: ^bb7
    cf.br ^bb9(%50 : i32)
  ^bb9(%51: i32):  // 2 preds: ^bb3, ^bb8
    cf.br ^bb10
  ^bb10:  // pred: ^bb9
    %52 = llvm.sext %51 : i32 to i64
    cf.br ^bb11(%52 : i64)
  ^bb11(%53: i64):  // 2 preds: ^bb1, ^bb10
    cf.br ^bb12
  ^bb12:  // pred: ^bb11
    %54 = llvm.mlir.constant(2 : i64) : i64
    %55 = llvm.sdiv %18, %54 : i64
    %56 = llvm.mlir.constant(0 : i64) : i64
    %57 = llvm.icmp "ne" %55, %56 : i64
    cf.cond_br %57, ^bb13, ^bb14
  ^bb13:  // pred: ^bb12
    cf.br ^bb23(%55 : i64)
  ^bb14:  // pred: ^bb12
    %58 = llvm.mlir.constant(0 : i64) : i64
    %59 = llvm.icmp "sgt" %18, %58 : i64
    cf.cond_br %59, ^bb15, ^bb16
  ^bb15:  // pred: ^bb14
    %60 = llvm.mlir.constant(1 : i32) : i32
    cf.br ^bb21(%60 : i32)
  ^bb16:  // pred: ^bb14
    %61 = llvm.mlir.constant(0 : i64) : i64
    %62 = llvm.icmp "eq" %18, %61 : i64
    cf.cond_br %62, ^bb17, ^bb18
  ^bb17:  // pred: ^bb16
    %63 = llvm.mlir.constant(0 : i32) : i32
    cf.br ^bb19(%63 : i32)
  ^bb18:  // pred: ^bb16
    %64 = llvm.mlir.constant(-1 : i32) : i32
    cf.br ^bb19(%64 : i32)
  ^bb19(%65: i32):  // 2 preds: ^bb17, ^bb18
    cf.br ^bb20
  ^bb20:  // pred: ^bb19
    cf.br ^bb21(%65 : i32)
  ^bb21(%66: i32):  // 2 preds: ^bb15, ^bb20
    cf.br ^bb22
  ^bb22:  // pred: ^bb21
    %67 = llvm.sext %66 : i32 to i64
    cf.br ^bb23(%67 : i64)
  ^bb23(%68: i64):  // 2 preds: ^bb13, ^bb22
    cf.br ^bb24
  ^bb24:  // pred: ^bb23
    %69 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %70 = llvm.insertvalue %38, %69[0] : !llvm.struct<(i32, i32, i32)> 
    %71 = llvm.insertvalue %15, %70[1] : !llvm.struct<(i32, i32, i32)> 
    %72 = llvm.insertvalue %16, %71[2] : !llvm.struct<(i32, i32, i32)> 
    %73 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %74 = llvm.insertvalue %53, %73[0] : !llvm.struct<(i64, i64)> 
    %75 = llvm.insertvalue %68, %74[1] : !llvm.struct<(i64, i64)> 
    %76 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %77 = llvm.insertvalue %72, %76[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %78 = llvm.insertvalue %75, %77[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %79 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %80 = llvm.extractvalue %79[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %81 = llvm.extractvalue %80[0] : !llvm.struct<(i32, i32, i32)> 
    %82 = llvm.extractvalue %80[1] : !llvm.struct<(i32, i32, i32)> 
    %83 = llvm.extractvalue %80[2] : !llvm.struct<(i32, i32, i32)> 
    %84 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %85 = llvm.insertvalue %81, %84[0] : !llvm.struct<(i32, i32, i32)> 
    %86 = llvm.insertvalue %82, %85[1] : !llvm.struct<(i32, i32, i32)> 
    %87 = llvm.insertvalue %83, %86[2] : !llvm.struct<(i32, i32, i32)> 
    %88 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %89 = llvm.insertvalue %87, %88[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %90 = llvm.insertvalue %8, %89[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %91 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %92 = llvm.extractvalue %79[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %93 = llvm.extractvalue %79[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %94 = llvm.extractvalue %79[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %95 = llvm.extractvalue %79[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %96 = llvm.extractvalue %79[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %97 = llvm.mlir.constant(1 : i32) : i32
    %98 = llvm.mlir.constant(0 : i32) : i32
    %99 = llvm.mlir.constant(-1 : i32) : i32
    %100 = llvm.mlir.constant(true) : i1
    %101 = llvm.select %100, %99, %97 : i1, i32
    %102 = llvm.add %101, %92 : i32
    %103 = llvm.sdiv %102, %7 : i32
    %104 = llvm.add %103, %97 : i32
    %105 = llvm.sub %98, %92 : i32
    %106 = llvm.sdiv %105, %7 : i32
    %107 = llvm.sub %98, %106 : i32
    %108 = llvm.icmp "slt" %92, %98 : i32
    %109 = llvm.icmp "sgt" %92, %98 : i32
    %110 = llvm.mlir.constant(false) : i1
    %111 = llvm.mlir.constant(true) : i1
    %112 = llvm.and %108, %110 : i1
    %113 = llvm.and %109, %111 : i1
    %114 = llvm.or %112, %113 : i1
    %115 = llvm.select %114, %104, %107 : i1, i32
    %116 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %117 = llvm.insertvalue %115, %116[0] : !llvm.struct<(i32, i32, i32)> 
    %118 = llvm.insertvalue %93, %117[1] : !llvm.struct<(i32, i32, i32)> 
    %119 = llvm.insertvalue %94, %118[2] : !llvm.struct<(i32, i32, i32)> 
    %120 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %121 = llvm.insertvalue %95, %120[0] : !llvm.struct<(i64, i64)> 
    %122 = llvm.insertvalue %96, %121[1] : !llvm.struct<(i64, i64)> 
    %123 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %124 = llvm.insertvalue %119, %123[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %125 = llvm.insertvalue %122, %124[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %126 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %127 = llvm.insertvalue %91, %126[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %128 = llvm.insertvalue %125, %127[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %129 = builtin.unrealized_conversion_cast %128 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_f32_
    %130 = llvm.extractvalue %90[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %131 = llvm.extractvalue %90[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %132 = llvm.extractvalue %90[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %133 = llvm.mlir.constant(1 : i32) : i32
    %134 = llvm.mlir.constant(0 : i32) : i32
    %135 = llvm.mlir.constant(-1 : i32) : i32
    %136 = llvm.mlir.constant(true) : i1
    %137 = llvm.select %136, %135, %133 : i1, i32
    %138 = llvm.add %137, %130 : i32
    %139 = llvm.sdiv %138, %7 : i32
    %140 = llvm.add %139, %133 : i32
    %141 = llvm.sub %134, %130 : i32
    %142 = llvm.sdiv %141, %7 : i32
    %143 = llvm.sub %134, %142 : i32
    %144 = llvm.icmp "slt" %130, %134 : i32
    %145 = llvm.icmp "sgt" %130, %134 : i32
    %146 = llvm.mlir.constant(false) : i1
    %147 = llvm.mlir.constant(true) : i1
    %148 = llvm.and %144, %146 : i1
    %149 = llvm.and %145, %147 : i1
    %150 = llvm.or %148, %149 : i1
    %151 = llvm.select %150, %140, %143 : i1, i32
    %152 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %153 = llvm.insertvalue %151, %152[0] : !llvm.struct<(i32, i32, i32)> 
    %154 = llvm.insertvalue %131, %153[1] : !llvm.struct<(i32, i32, i32)> 
    %155 = llvm.insertvalue %132, %154[2] : !llvm.struct<(i32, i32, i32)> 
    %156 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %157 = llvm.insertvalue %155, %156[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %158 = llvm.insertvalue %6, %157[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)> 
    %159 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>
    %160 = llvm.insertvalue %9, %159[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %161 = llvm.insertvalue %158, %160[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> 
    %162 = builtin.unrealized_conversion_cast %161 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %163 = llvm.extractvalue %78[0, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %164 = llvm.extractvalue %78[0, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %165 = llvm.extractvalue %78[0, 2] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %166 = llvm.extractvalue %78[1, 0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %167 = llvm.extractvalue %78[1, 1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %168 = llvm.mlir.constant(1 : i32) : i32
    %169 = llvm.mlir.constant(0 : i32) : i32
    %170 = llvm.mlir.constant(-1 : i32) : i32
    %171 = llvm.mlir.constant(true) : i1
    %172 = llvm.select %171, %170, %168 : i1, i32
    %173 = llvm.add %172, %163 : i32
    %174 = llvm.sdiv %173, %5 : i32
    %175 = llvm.add %174, %168 : i32
    %176 = llvm.sub %169, %163 : i32
    %177 = llvm.sdiv %176, %5 : i32
    %178 = llvm.sub %169, %177 : i32
    %179 = llvm.icmp "slt" %163, %169 : i32
    %180 = llvm.icmp "sgt" %163, %169 : i32
    %181 = llvm.mlir.constant(false) : i1
    %182 = llvm.mlir.constant(true) : i1
    %183 = llvm.and %179, %181 : i1
    %184 = llvm.and %180, %182 : i1
    %185 = llvm.or %183, %184 : i1
    %186 = llvm.select %185, %175, %178 : i1, i32
    %187 = llvm.mlir.undef : !llvm.struct<(i32, i32, i32)>
    %188 = llvm.insertvalue %186, %187[0] : !llvm.struct<(i32, i32, i32)> 
    %189 = llvm.insertvalue %164, %188[1] : !llvm.struct<(i32, i32, i32)> 
    %190 = llvm.insertvalue %165, %189[2] : !llvm.struct<(i32, i32, i32)> 
    %191 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %192 = llvm.insertvalue %166, %191[0] : !llvm.struct<(i64, i64)> 
    %193 = llvm.insertvalue %167, %192[1] : !llvm.struct<(i64, i64)> 
    %194 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %195 = llvm.insertvalue %190, %194[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %196 = llvm.insertvalue %193, %195[1] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %197 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>
    %198 = llvm.insertvalue %11, %197[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %199 = llvm.insertvalue %196, %198[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> 
    %200 = builtin.unrealized_conversion_cast %199 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)> to !memref_gmem_i8_
    %201 = llvm.extractvalue %125[0] : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)> 
    %202 = llvm.extractvalue %201[0] : !llvm.struct<(i32, i32, i32)> 
    %203 = llvm.extractvalue %201[1] : !llvm.struct<(i32, i32, i32)> 
    %204 = llvm.extractvalue %201[2] : !llvm.struct<(i32, i32, i32)> 
    %205 = llvm.mul %202, %203 : i32
    %206 = llvm.mul %205, %204 : i32
    %207 = llvm.sext %206 : i32 to i64
    %208 = builtin.unrealized_conversion_cast %207 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%208, %4, %4) threads in (%2, %4, %4)  dynamic_shared_memory_size %0 args(%129 : !memref_gmem_f32_, %200 : !memref_gmem_i8_, %162 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %81 : i32, %82 : i32, %83 : i32) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0, %arg1) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> ()
    llvm.return
  }
}
