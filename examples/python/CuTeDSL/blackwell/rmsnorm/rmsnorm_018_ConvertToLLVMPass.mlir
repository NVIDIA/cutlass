#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.mlir.global external @__dynamic_shmem__0() {addr_space = 3 : i32, alignment = 1024 : i64, dso_local} : !llvm.array<0 x i8>
    llvm.func @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %1 = llvm.mlir.constant(8 : i32) : i32
      %2 = llvm.mlir.constant(1 : i32) : i32
      %3 = llvm.alloca %1 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %4 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %5 = llvm.mlir.constant(8 : i32) : i32
      %6 = llvm.mlir.constant(1 : i32) : i32
      %7 = llvm.alloca %5 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %8 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %9 = llvm.mlir.constant(64 : i32) : i32
      %10 = llvm.mlir.constant(1 : i32) : i32
      %11 = llvm.alloca %9 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %12 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %13 = llvm.mlir.constant(64 : i32) : i32
      %14 = llvm.mlir.constant(1 : i32) : i32
      %15 = llvm.alloca %13 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %16 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %17 = llvm.mlir.constant(64 : i32) : i32
      %18 = llvm.mlir.constant(1 : i32) : i32
      %19 = llvm.alloca %17 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %20 = llvm.mlir.constant(4.096000e+03 : f32) : f32
      %21 = llvm.mlir.constant(32 : i32) : i32
      %22 = llvm.mlir.constant(4 : i32) : i32
      %23 = llvm.mlir.constant(31 : i32) : i32
      %24 = llvm.mlir.constant(16 : i32) : i32
      %25 = llvm.mlir.constant(-1 : i32) : i32
      %26 = llvm.mlir.constant(0.000000e+00 : f32) : f32
      %27 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %28 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %29 = llvm.mlir.poison : !llvm.struct<()>
      %30 = llvm.mlir.poison : !llvm.struct<()>
      %31 = llvm.mlir.poison : !llvm.struct<()>
      %32 = llvm.mlir.poison : !llvm.struct<()>
      %33 = llvm.mlir.poison : !llvm.struct<()>
      %34 = llvm.mlir.poison : !llvm.struct<()>
      %35 = llvm.mlir.poison : !llvm.struct<()>
      %36 = llvm.mlir.constant(0 : i8) : i8
      %37 = llvm.mlir.poison : !llvm.struct<()>
      %38 = llvm.mlir.poison : !llvm.struct<()>
      %39 = llvm.mlir.poison : !llvm.struct<()>
      %40 = llvm.mlir.poison : !llvm.struct<()>
      %41 = llvm.mlir.poison : !llvm.struct<()>
      %42 = llvm.mlir.poison : !llvm.struct<()>
      %43 = llvm.mlir.poison : !llvm.struct<()>
      %44 = llvm.mlir.poison : !llvm.struct<()>
      %45 = llvm.mlir.poison : !llvm.struct<()>
      %46 = llvm.mlir.poison : !llvm.struct<()>
      %47 = llvm.mlir.poison : !llvm.struct<()>
      %48 = llvm.mlir.poison : !llvm.struct<()>
      %49 = llvm.mlir.poison : !llvm.struct<()>
      %50 = llvm.mlir.constant(1 : i32) : i32
      %51 = llvm.mlir.constant(0 : i32) : i32
      %52 = llvm.mlir.poison : !llvm.struct<()>
      %53 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %54 = llvm.mlir.poison : !llvm.struct<()>
      %55 = llvm.mlir.poison : !llvm.struct<()>
      %56 = llvm.mlir.poison : !llvm.struct<()>
      %57 = llvm.mlir.poison : !llvm.struct<()>
      %58 = llvm.mlir.poison : !llvm.struct<()>
      %59 = llvm.mlir.poison : !llvm.struct<()>
      %60 = llvm.mlir.poison : !llvm.struct<()>
      %61 = llvm.mlir.poison : !llvm.struct<()>
      %62 = llvm.mlir.poison : !llvm.struct<()>
      %63 = llvm.mlir.poison : !llvm.struct<()>
      %64 = llvm.mlir.poison : !llvm.struct<()>
      %65 = llvm.mlir.poison : !llvm.struct<()>
      %66 = llvm.mlir.poison : !llvm.struct<()>
      %67 = llvm.mlir.poison : !llvm.struct<()>
      %68 = llvm.mlir.poison : !llvm.struct<()>
      %69 = llvm.mlir.poison : !llvm.struct<()>
      %70 = llvm.mlir.constant(4096 : i32) : i32
      %71 = llvm.mlir.constant(8 : i32) : i32
      %72 = llvm.mlir.constant(64 : i32) : i32
      %73 = llvm.mlir.poison : !llvm.struct<()>
      %74 = llvm.mlir.poison : !llvm.struct<()>
      %75 = llvm.mlir.constant(2 : i32) : i32
      %76 = llvm.mlir.poison : !llvm.struct<()>
      %77 = llvm.mlir.poison : !llvm.struct<()>
      %78 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
      %79 = llvm.mlir.poison : !llvm.struct<()>
      %80 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
      %81 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %82 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %83 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %84 = llvm.extractvalue %83[0] : !llvm.struct<(i32, struct<()>)> 
      %85 = llvm.mlir.undef : !llvm.struct<()>
      %86 = llvm.mlir.addressof @__dynamic_shmem__0 : !llvm.ptr<3>
      %87 = llvm.getelementptr %86[0] : (!llvm.ptr<3>) -> !llvm.ptr<3>, !llvm.array<0 x i8>
      %88 = llvm.mlir.constant(16384 : i32) : i32
      %89 = llvm.getelementptr %87[%88] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i8
      %90 = llvm.mlir.undef : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %91 = llvm.insertvalue %89, %90[0] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %92 = llvm.insertvalue %78, %91[1] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %93 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
      %94 = llvm.insertvalue %84, %93[0] : !llvm.struct<(i32, struct<()>)> 
      %95 = llvm.insertvalue %76, %94[1] : !llvm.struct<(i32, struct<()>)> 
      %96 = llvm.extractvalue %83[0] : !llvm.struct<(i32, struct<()>)> 
      %97 = llvm.mlir.constant(1 : i32) : i32
      %98 = llvm.mlir.constant(0 : i32) : i32
      %99 = llvm.mlir.constant(-1 : i32) : i32
      %100 = llvm.mlir.constant(true) : i1
      %101 = llvm.select %100, %99, %97 : i1, i32
      %102 = llvm.add %101, %96 : i32
      %103 = llvm.sdiv %102, %75 : i32
      %104 = llvm.add %103, %97 : i32
      %105 = llvm.sub %98, %96 : i32
      %106 = llvm.sdiv %105, %75 : i32
      %107 = llvm.sub %98, %106 : i32
      %108 = llvm.icmp "slt" %96, %98 : i32
      %109 = llvm.icmp "sgt" %96, %98 : i32
      %110 = llvm.mlir.constant(false) : i1
      %111 = llvm.mlir.constant(true) : i1
      %112 = llvm.and %108, %110 : i1
      %113 = llvm.and %109, %111 : i1
      %114 = llvm.or %112, %113 : i1
      %115 = llvm.select %114, %104, %107 : i1, i32
      %116 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
      %117 = llvm.insertvalue %115, %116[0] : !llvm.struct<(i32, struct<()>)> 
      %118 = llvm.insertvalue %74, %117[1] : !llvm.struct<(i32, struct<()>)> 
      %119 = llvm.extractvalue %118[0] : !llvm.struct<(i32, struct<()>)> 
      %120 = llvm.extractvalue %118[1] : !llvm.struct<(i32, struct<()>)> 
      %121 = llvm.mlir.constant(8192 : i32) : i32
      %122 = llvm.mul %82, %121 : i32
      %123 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %124 = llvm.getelementptr %123[%122] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %125 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %126 = llvm.extractvalue %125[0] : !llvm.struct<(i32, struct<()>)> 
      %127 = llvm.mlir.constant(1 : i32) : i32
      %128 = llvm.mlir.constant(0 : i32) : i32
      %129 = llvm.mlir.constant(-1 : i32) : i32
      %130 = llvm.mlir.constant(true) : i1
      %131 = llvm.select %130, %129, %127 : i1, i32
      %132 = llvm.add %131, %126 : i32
      %133 = llvm.sdiv %132, %75 : i32
      %134 = llvm.add %133, %127 : i32
      %135 = llvm.sub %128, %126 : i32
      %136 = llvm.sdiv %135, %75 : i32
      %137 = llvm.sub %128, %136 : i32
      %138 = llvm.icmp "slt" %126, %128 : i32
      %139 = llvm.icmp "sgt" %126, %128 : i32
      %140 = llvm.mlir.constant(false) : i1
      %141 = llvm.mlir.constant(true) : i1
      %142 = llvm.and %138, %140 : i1
      %143 = llvm.and %139, %141 : i1
      %144 = llvm.or %142, %143 : i1
      %145 = llvm.select %144, %134, %137 : i1, i32
      %146 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
      %147 = llvm.insertvalue %145, %146[0] : !llvm.struct<(i32, struct<()>)> 
      %148 = llvm.insertvalue %74, %147[1] : !llvm.struct<(i32, struct<()>)> 
      %149 = llvm.extractvalue %148[0] : !llvm.struct<(i32, struct<()>)> 
      %150 = llvm.extractvalue %148[1] : !llvm.struct<(i32, struct<()>)> 
      %151 = llvm.mlir.constant(8192 : i32) : i32
      %152 = llvm.mul %82, %151 : i32
      %153 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %154 = llvm.getelementptr %153[%152] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %155 = llvm.extractvalue %95[0] : !llvm.struct<(i32, struct<()>)> 
      %156 = llvm.mlir.constant(1 : i32) : i32
      %157 = llvm.mlir.constant(0 : i32) : i32
      %158 = llvm.mlir.constant(-1 : i32) : i32
      %159 = llvm.mlir.constant(true) : i1
      %160 = llvm.select %159, %158, %156 : i1, i32
      %161 = llvm.add %160, %155 : i32
      %162 = llvm.sdiv %161, %75 : i32
      %163 = llvm.add %162, %156 : i32
      %164 = llvm.sub %157, %155 : i32
      %165 = llvm.sdiv %164, %75 : i32
      %166 = llvm.sub %157, %165 : i32
      %167 = llvm.icmp "slt" %155, %157 : i32
      %168 = llvm.icmp "sgt" %155, %157 : i32
      %169 = llvm.mlir.constant(false) : i1
      %170 = llvm.mlir.constant(true) : i1
      %171 = llvm.and %167, %169 : i1
      %172 = llvm.and %168, %170 : i1
      %173 = llvm.or %171, %172 : i1
      %174 = llvm.select %173, %163, %166 : i1, i32
      %175 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
      %176 = llvm.insertvalue %174, %175[0] : !llvm.struct<(i32, struct<()>)> 
      %177 = llvm.insertvalue %73, %176[1] : !llvm.struct<(i32, struct<()>)> 
      %178 = llvm.extractvalue %177[0] : !llvm.struct<(i32, struct<()>)> 
      %179 = llvm.extractvalue %177[1] : !llvm.struct<(i32, struct<()>)> 
      %180 = llvm.mlir.constant(2 : i32) : i32
      %181 = llvm.mul %82, %180 : i32
      %182 = llvm.mlir.undef : !llvm.struct<()>
      %183 = llvm.mlir.undef : !llvm.struct<()>
      %184 = llvm.mlir.undef : !llvm.struct<()>
      %185 = llvm.mlir.undef : !llvm.struct<()>
      %186 = llvm.mlir.undef : !llvm.struct<()>
      %187 = llvm.sdiv %81, %72 : i32
      %188 = llvm.srem %81, %72 : i32
      %189 = llvm.mul %188, %71 : i32
      %190 = llvm.mul %187, %70 : i32
      %191 = llvm.add %189, %190 : i32
      %192 = llvm.getelementptr %124[%191] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %193 = llvm.getelementptr %87[%191] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %194 = llvm.getelementptr %154[%191] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %195 = builtin.unrealized_conversion_cast %194 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %196 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %197 = llvm.insertvalue %187, %196[0] : !llvm.struct<(i32, i32)> 
      %198 = llvm.insertvalue %189, %197[1] : !llvm.struct<(i32, i32)> 
      %199 = llvm.extractvalue %198[0] : !llvm.struct<(i32, i32)> 
      %200 = llvm.extractvalue %198[1] : !llvm.struct<(i32, i32)> 
      %201 = llvm.add %181, %199 : i32
      %202 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %203 = llvm.insertvalue %201, %202[0] : !llvm.struct<(i32, i32)> 
      %204 = llvm.insertvalue %200, %203[1] : !llvm.struct<(i32, i32)> 
      %205 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %206 = llvm.insertvalue %19, %205[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %207 = llvm.insertvalue %16, %206[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %208 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %209 = llvm.insertvalue %15, %208[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %210 = llvm.insertvalue %12, %209[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %211 = llvm.extractvalue %210[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %212 = builtin.unrealized_conversion_cast %211 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %213 = llvm.getelementptr %80[%189] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %214 = builtin.unrealized_conversion_cast %213 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %215 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %216 = llvm.insertvalue %11, %215[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %217 = llvm.insertvalue %8, %216[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %218 = llvm.extractvalue %217[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %219 = builtin.unrealized_conversion_cast %218 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %220 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<()>)>
      %221 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %222 = llvm.insertvalue %218, %221[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %223 = llvm.insertvalue %220, %222[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %224 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %225 = llvm.insertvalue %7, %224[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %226 = llvm.insertvalue %4, %225[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %227 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %228 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %229 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %230 = llvm.mlir.constant(4096 : i32) : i32
      %231 = llvm.icmp "slt" %229, %230 : i32
      %232 = llvm.zext %231 : i1 to i8
      %233 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %234 = llvm.extractvalue %233[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %235 = llvm.extractvalue %233[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %236 = llvm.mlir.undef : !llvm.struct<()>
      %237 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %238 = llvm.mlir.constant(0 : i32) : i32
      %239 = llvm.getelementptr %237[%238] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %240 = llvm.ptrtoint %239 : !llvm.ptr to i64
      %241 = llvm.inttoptr %240 : i64 to !llvm.ptr
      llvm.store %232, %241 {alignment = 32 : i64} : i8, !llvm.ptr
      %242 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %243 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %244 = llvm.mlir.constant(512 : i32) : i32
      %245 = llvm.add %243, %244 : i32
      %246 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %247 = llvm.insertvalue %242, %246[0] : !llvm.struct<(i32, i32)> 
      %248 = llvm.insertvalue %245, %247[1] : !llvm.struct<(i32, i32)> 
      %249 = llvm.extractvalue %248[0] : !llvm.struct<(i32, i32)> 
      %250 = llvm.extractvalue %248[1] : !llvm.struct<(i32, i32)> 
      %251 = llvm.icmp "slt" %250, %230 : i32
      %252 = llvm.zext %251 : i1 to i8
      %253 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %254 = llvm.extractvalue %253[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %255 = llvm.extractvalue %253[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %256 = llvm.mlir.undef : !llvm.struct<()>
      %257 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %258 = llvm.mlir.constant(1 : i32) : i32
      %259 = llvm.getelementptr %257[%258] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %260 = llvm.ptrtoint %259 : !llvm.ptr to i64
      %261 = llvm.inttoptr %260 : i64 to !llvm.ptr
      llvm.store %252, %261 {alignment = 1 : i64} : i8, !llvm.ptr
      %262 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %263 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %264 = llvm.mlir.constant(1024 : i32) : i32
      %265 = llvm.add %263, %264 : i32
      %266 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %267 = llvm.insertvalue %262, %266[0] : !llvm.struct<(i32, i32)> 
      %268 = llvm.insertvalue %265, %267[1] : !llvm.struct<(i32, i32)> 
      %269 = llvm.extractvalue %268[0] : !llvm.struct<(i32, i32)> 
      %270 = llvm.extractvalue %268[1] : !llvm.struct<(i32, i32)> 
      %271 = llvm.icmp "slt" %270, %230 : i32
      %272 = llvm.zext %271 : i1 to i8
      %273 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %274 = llvm.extractvalue %273[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %275 = llvm.extractvalue %273[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %276 = llvm.mlir.undef : !llvm.struct<()>
      %277 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %278 = llvm.mlir.constant(2 : i32) : i32
      %279 = llvm.getelementptr %277[%278] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %280 = llvm.ptrtoint %279 : !llvm.ptr to i64
      %281 = llvm.inttoptr %280 : i64 to !llvm.ptr
      llvm.store %272, %281 {alignment = 2 : i64} : i8, !llvm.ptr
      %282 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %283 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %284 = llvm.mlir.constant(1536 : i32) : i32
      %285 = llvm.add %283, %284 : i32
      %286 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %287 = llvm.insertvalue %282, %286[0] : !llvm.struct<(i32, i32)> 
      %288 = llvm.insertvalue %285, %287[1] : !llvm.struct<(i32, i32)> 
      %289 = llvm.extractvalue %288[0] : !llvm.struct<(i32, i32)> 
      %290 = llvm.extractvalue %288[1] : !llvm.struct<(i32, i32)> 
      %291 = llvm.icmp "slt" %290, %230 : i32
      %292 = llvm.zext %291 : i1 to i8
      %293 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %294 = llvm.extractvalue %293[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %295 = llvm.extractvalue %293[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %296 = llvm.mlir.undef : !llvm.struct<()>
      %297 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %298 = llvm.mlir.constant(3 : i32) : i32
      %299 = llvm.getelementptr %297[%298] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %300 = llvm.ptrtoint %299 : !llvm.ptr to i64
      %301 = llvm.inttoptr %300 : i64 to !llvm.ptr
      llvm.store %292, %301 {alignment = 1 : i64} : i8, !llvm.ptr
      %302 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %303 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %304 = llvm.mlir.constant(2048 : i32) : i32
      %305 = llvm.add %303, %304 : i32
      %306 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %307 = llvm.insertvalue %302, %306[0] : !llvm.struct<(i32, i32)> 
      %308 = llvm.insertvalue %305, %307[1] : !llvm.struct<(i32, i32)> 
      %309 = llvm.extractvalue %308[0] : !llvm.struct<(i32, i32)> 
      %310 = llvm.extractvalue %308[1] : !llvm.struct<(i32, i32)> 
      %311 = llvm.icmp "slt" %310, %230 : i32
      %312 = llvm.zext %311 : i1 to i8
      %313 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %314 = llvm.extractvalue %313[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %315 = llvm.extractvalue %313[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %316 = llvm.mlir.undef : !llvm.struct<()>
      %317 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %318 = llvm.mlir.constant(4 : i32) : i32
      %319 = llvm.getelementptr %317[%318] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %320 = llvm.ptrtoint %319 : !llvm.ptr to i64
      %321 = llvm.inttoptr %320 : i64 to !llvm.ptr
      llvm.store %312, %321 {alignment = 4 : i64} : i8, !llvm.ptr
      %322 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %323 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %324 = llvm.mlir.constant(2560 : i32) : i32
      %325 = llvm.add %323, %324 : i32
      %326 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %327 = llvm.insertvalue %322, %326[0] : !llvm.struct<(i32, i32)> 
      %328 = llvm.insertvalue %325, %327[1] : !llvm.struct<(i32, i32)> 
      %329 = llvm.extractvalue %328[0] : !llvm.struct<(i32, i32)> 
      %330 = llvm.extractvalue %328[1] : !llvm.struct<(i32, i32)> 
      %331 = llvm.icmp "slt" %330, %230 : i32
      %332 = llvm.zext %331 : i1 to i8
      %333 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %334 = llvm.extractvalue %333[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %335 = llvm.extractvalue %333[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %336 = llvm.mlir.undef : !llvm.struct<()>
      %337 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %338 = llvm.mlir.constant(5 : i32) : i32
      %339 = llvm.getelementptr %337[%338] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %340 = llvm.ptrtoint %339 : !llvm.ptr to i64
      %341 = llvm.inttoptr %340 : i64 to !llvm.ptr
      llvm.store %332, %341 {alignment = 1 : i64} : i8, !llvm.ptr
      %342 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %343 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %344 = llvm.mlir.constant(3072 : i32) : i32
      %345 = llvm.add %343, %344 : i32
      %346 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %347 = llvm.insertvalue %342, %346[0] : !llvm.struct<(i32, i32)> 
      %348 = llvm.insertvalue %345, %347[1] : !llvm.struct<(i32, i32)> 
      %349 = llvm.extractvalue %348[0] : !llvm.struct<(i32, i32)> 
      %350 = llvm.extractvalue %348[1] : !llvm.struct<(i32, i32)> 
      %351 = llvm.icmp "slt" %350, %230 : i32
      %352 = llvm.zext %351 : i1 to i8
      %353 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %354 = llvm.extractvalue %353[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %355 = llvm.extractvalue %353[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %356 = llvm.mlir.undef : !llvm.struct<()>
      %357 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %358 = llvm.mlir.constant(6 : i32) : i32
      %359 = llvm.getelementptr %357[%358] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %360 = llvm.ptrtoint %359 : !llvm.ptr to i64
      %361 = llvm.inttoptr %360 : i64 to !llvm.ptr
      llvm.store %352, %361 {alignment = 2 : i64} : i8, !llvm.ptr
      %362 = llvm.extractvalue %204[0] : !llvm.struct<(i32, i32)> 
      %363 = llvm.extractvalue %204[1] : !llvm.struct<(i32, i32)> 
      %364 = llvm.mlir.constant(3584 : i32) : i32
      %365 = llvm.add %363, %364 : i32
      %366 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %367 = llvm.insertvalue %362, %366[0] : !llvm.struct<(i32, i32)> 
      %368 = llvm.insertvalue %365, %367[1] : !llvm.struct<(i32, i32)> 
      %369 = llvm.extractvalue %368[0] : !llvm.struct<(i32, i32)> 
      %370 = llvm.extractvalue %368[1] : !llvm.struct<(i32, i32)> 
      %371 = llvm.icmp "slt" %370, %230 : i32
      %372 = llvm.zext %371 : i1 to i8
      %373 = llvm.extractvalue %226[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %374 = llvm.extractvalue %373[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %375 = llvm.extractvalue %373[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %376 = llvm.mlir.undef : !llvm.struct<()>
      %377 = llvm.extractvalue %226[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %378 = llvm.mlir.constant(7 : i32) : i32
      %379 = llvm.getelementptr %377[%378] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %380 = llvm.ptrtoint %379 : !llvm.ptr to i64
      %381 = llvm.inttoptr %380 : i64 to !llvm.ptr
      llvm.store %372, %381 {alignment = 1 : i64} : i8, !llvm.ptr
      %382 = llvm.icmp "slt" %228, %84 : i32
      llvm.cond_br %382, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %383 = llvm.mlir.constant(1 : i32) : i32
      %384 = llvm.mlir.constant(512 : i32) : i32
      %385 = llvm.getelementptr %192[%384] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %386 = llvm.mlir.constant(512 : i32) : i32
      %387 = llvm.getelementptr %193[%386] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %388 = llvm.mlir.constant(1024 : i32) : i32
      %389 = llvm.getelementptr %192[%388] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %390 = llvm.mlir.constant(1024 : i32) : i32
      %391 = llvm.getelementptr %193[%390] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %392 = llvm.mlir.constant(1536 : i32) : i32
      %393 = llvm.getelementptr %192[%392] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %394 = llvm.mlir.constant(1536 : i32) : i32
      %395 = llvm.getelementptr %193[%394] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %396 = llvm.mlir.constant(2048 : i32) : i32
      %397 = llvm.getelementptr %192[%396] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %398 = llvm.mlir.constant(2048 : i32) : i32
      %399 = llvm.getelementptr %193[%398] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %400 = llvm.mlir.constant(2560 : i32) : i32
      %401 = llvm.getelementptr %192[%400] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %402 = llvm.mlir.constant(2560 : i32) : i32
      %403 = llvm.getelementptr %193[%402] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %404 = llvm.mlir.constant(3072 : i32) : i32
      %405 = llvm.getelementptr %192[%404] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %406 = llvm.mlir.constant(3072 : i32) : i32
      %407 = llvm.getelementptr %193[%406] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %408 = llvm.mlir.constant(3584 : i32) : i32
      %409 = llvm.getelementptr %192[%408] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %410 = llvm.mlir.constant(3584 : i32) : i32
      %411 = llvm.getelementptr %193[%410] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      llvm.br ^bb2(%51 : i32)
    ^bb2(%412: i32):  // 2 preds: ^bb1, ^bb3
      %413 = llvm.icmp "slt" %412, %383 : i32
      llvm.cond_br %413, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %414 = llvm.extractvalue %53[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %415 = llvm.extractvalue %53[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %416 = llvm.getelementptr %227[%412] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %417 = builtin.unrealized_conversion_cast %416 : !llvm.ptr to !cute.ptr<i8, rmem>
      %418 = builtin.unrealized_conversion_cast %417 : !cute.ptr<i8, rmem> to !llvm.ptr
      %419 = llvm.load %418 : !llvm.ptr -> i8
      %420 = llvm.trunc %419 : i8 to i1
      %421 = llvm.mlir.constant(16 : i32) : i32
      %422 = llvm.mlir.zero : i32
      %423 = llvm.select %420, %421, %422 : i1, i32
      nvvm.cp.async.shared.global %193, %192, 16, cache =  ca, %423 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %424 = llvm.mlir.constant(1 : i32) : i32
      %425 = llvm.getelementptr %416[%424] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %426 = builtin.unrealized_conversion_cast %425 : !llvm.ptr to !cute.ptr<i8, rmem>
      %427 = builtin.unrealized_conversion_cast %426 : !cute.ptr<i8, rmem> to !llvm.ptr
      %428 = llvm.load %427 : !llvm.ptr -> i8
      %429 = llvm.trunc %428 : i8 to i1
      %430 = llvm.mlir.constant(16 : i32) : i32
      %431 = llvm.mlir.zero : i32
      %432 = llvm.select %429, %430, %431 : i1, i32
      nvvm.cp.async.shared.global %387, %385, 16, cache =  ca, %432 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %433 = llvm.mlir.constant(2 : i32) : i32
      %434 = llvm.getelementptr %416[%433] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %435 = builtin.unrealized_conversion_cast %434 : !llvm.ptr to !cute.ptr<i8, rmem>
      %436 = builtin.unrealized_conversion_cast %435 : !cute.ptr<i8, rmem> to !llvm.ptr
      %437 = llvm.load %436 : !llvm.ptr -> i8
      %438 = llvm.trunc %437 : i8 to i1
      %439 = llvm.mlir.constant(16 : i32) : i32
      %440 = llvm.mlir.zero : i32
      %441 = llvm.select %438, %439, %440 : i1, i32
      nvvm.cp.async.shared.global %391, %389, 16, cache =  ca, %441 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %442 = llvm.mlir.constant(3 : i32) : i32
      %443 = llvm.getelementptr %416[%442] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %444 = builtin.unrealized_conversion_cast %443 : !llvm.ptr to !cute.ptr<i8, rmem>
      %445 = builtin.unrealized_conversion_cast %444 : !cute.ptr<i8, rmem> to !llvm.ptr
      %446 = llvm.load %445 : !llvm.ptr -> i8
      %447 = llvm.trunc %446 : i8 to i1
      %448 = llvm.mlir.constant(16 : i32) : i32
      %449 = llvm.mlir.zero : i32
      %450 = llvm.select %447, %448, %449 : i1, i32
      nvvm.cp.async.shared.global %395, %393, 16, cache =  ca, %450 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %451 = llvm.mlir.constant(4 : i32) : i32
      %452 = llvm.getelementptr %416[%451] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %453 = builtin.unrealized_conversion_cast %452 : !llvm.ptr to !cute.ptr<i8, rmem>
      %454 = builtin.unrealized_conversion_cast %453 : !cute.ptr<i8, rmem> to !llvm.ptr
      %455 = llvm.load %454 : !llvm.ptr -> i8
      %456 = llvm.trunc %455 : i8 to i1
      %457 = llvm.mlir.constant(16 : i32) : i32
      %458 = llvm.mlir.zero : i32
      %459 = llvm.select %456, %457, %458 : i1, i32
      nvvm.cp.async.shared.global %399, %397, 16, cache =  ca, %459 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %460 = llvm.mlir.constant(5 : i32) : i32
      %461 = llvm.getelementptr %416[%460] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %462 = builtin.unrealized_conversion_cast %461 : !llvm.ptr to !cute.ptr<i8, rmem>
      %463 = builtin.unrealized_conversion_cast %462 : !cute.ptr<i8, rmem> to !llvm.ptr
      %464 = llvm.load %463 : !llvm.ptr -> i8
      %465 = llvm.trunc %464 : i8 to i1
      %466 = llvm.mlir.constant(16 : i32) : i32
      %467 = llvm.mlir.zero : i32
      %468 = llvm.select %465, %466, %467 : i1, i32
      nvvm.cp.async.shared.global %403, %401, 16, cache =  ca, %468 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %469 = llvm.mlir.constant(6 : i32) : i32
      %470 = llvm.getelementptr %416[%469] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %471 = builtin.unrealized_conversion_cast %470 : !llvm.ptr to !cute.ptr<i8, rmem>
      %472 = builtin.unrealized_conversion_cast %471 : !cute.ptr<i8, rmem> to !llvm.ptr
      %473 = llvm.load %472 : !llvm.ptr -> i8
      %474 = llvm.trunc %473 : i8 to i1
      %475 = llvm.mlir.constant(16 : i32) : i32
      %476 = llvm.mlir.zero : i32
      %477 = llvm.select %474, %475, %476 : i1, i32
      nvvm.cp.async.shared.global %407, %405, 16, cache =  ca, %477 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %478 = llvm.mlir.constant(7 : i32) : i32
      %479 = llvm.getelementptr %416[%478] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %480 = builtin.unrealized_conversion_cast %479 : !llvm.ptr to !cute.ptr<i8, rmem>
      %481 = builtin.unrealized_conversion_cast %480 : !cute.ptr<i8, rmem> to !llvm.ptr
      %482 = llvm.load %481 : !llvm.ptr -> i8
      %483 = llvm.trunc %482 : i8 to i1
      %484 = llvm.mlir.constant(16 : i32) : i32
      %485 = llvm.mlir.zero : i32
      %486 = llvm.select %483, %484, %485 : i1, i32
      nvvm.cp.async.shared.global %411, %409, 16, cache =  ca, %486 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %487 = llvm.add %412, %50 : i32
      llvm.br ^bb2(%487 : i32)
    ^bb4:  // pred: ^bb2
      llvm.br ^bb5
    ^bb5:  // 2 preds: ^bb0, ^bb4
      nvvm.cp.async.commit.group
      %488 = llvm.mlir.undef : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)>
      %489 = llvm.insertvalue %3, %488[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %490 = llvm.insertvalue %0, %489[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %491 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %492 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %493 = llvm.extractvalue %492[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %494 = llvm.extractvalue %492[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %495 = llvm.mlir.undef : !llvm.struct<()>
      %496 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %497 = llvm.mlir.constant(0 : i32) : i32
      %498 = llvm.getelementptr %496[%497] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %499 = llvm.ptrtoint %498 : !llvm.ptr to i64
      %500 = llvm.inttoptr %499 : i64 to !llvm.ptr
      llvm.store %232, %500 {alignment = 32 : i64} : i8, !llvm.ptr
      %501 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %502 = llvm.extractvalue %501[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %503 = llvm.extractvalue %501[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %504 = llvm.mlir.undef : !llvm.struct<()>
      %505 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %506 = llvm.mlir.constant(1 : i32) : i32
      %507 = llvm.getelementptr %505[%506] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %508 = llvm.ptrtoint %507 : !llvm.ptr to i64
      %509 = llvm.inttoptr %508 : i64 to !llvm.ptr
      llvm.store %252, %509 {alignment = 1 : i64} : i8, !llvm.ptr
      %510 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %511 = llvm.extractvalue %510[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %512 = llvm.extractvalue %510[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %513 = llvm.mlir.undef : !llvm.struct<()>
      %514 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %515 = llvm.mlir.constant(2 : i32) : i32
      %516 = llvm.getelementptr %514[%515] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %517 = llvm.ptrtoint %516 : !llvm.ptr to i64
      %518 = llvm.inttoptr %517 : i64 to !llvm.ptr
      llvm.store %272, %518 {alignment = 2 : i64} : i8, !llvm.ptr
      %519 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %520 = llvm.extractvalue %519[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %521 = llvm.extractvalue %519[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %522 = llvm.mlir.undef : !llvm.struct<()>
      %523 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %524 = llvm.mlir.constant(3 : i32) : i32
      %525 = llvm.getelementptr %523[%524] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %526 = llvm.ptrtoint %525 : !llvm.ptr to i64
      %527 = llvm.inttoptr %526 : i64 to !llvm.ptr
      llvm.store %292, %527 {alignment = 1 : i64} : i8, !llvm.ptr
      %528 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %529 = llvm.extractvalue %528[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %530 = llvm.extractvalue %528[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %531 = llvm.mlir.undef : !llvm.struct<()>
      %532 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %533 = llvm.mlir.constant(4 : i32) : i32
      %534 = llvm.getelementptr %532[%533] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %535 = llvm.ptrtoint %534 : !llvm.ptr to i64
      %536 = llvm.inttoptr %535 : i64 to !llvm.ptr
      llvm.store %312, %536 {alignment = 4 : i64} : i8, !llvm.ptr
      %537 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %538 = llvm.extractvalue %537[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %539 = llvm.extractvalue %537[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %540 = llvm.mlir.undef : !llvm.struct<()>
      %541 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %542 = llvm.mlir.constant(5 : i32) : i32
      %543 = llvm.getelementptr %541[%542] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %544 = llvm.ptrtoint %543 : !llvm.ptr to i64
      %545 = llvm.inttoptr %544 : i64 to !llvm.ptr
      llvm.store %332, %545 {alignment = 1 : i64} : i8, !llvm.ptr
      %546 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %547 = llvm.extractvalue %546[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %548 = llvm.extractvalue %546[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %549 = llvm.mlir.undef : !llvm.struct<()>
      %550 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %551 = llvm.mlir.constant(6 : i32) : i32
      %552 = llvm.getelementptr %550[%551] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %553 = llvm.ptrtoint %552 : !llvm.ptr to i64
      %554 = llvm.inttoptr %553 : i64 to !llvm.ptr
      llvm.store %352, %554 {alignment = 2 : i64} : i8, !llvm.ptr
      %555 = llvm.extractvalue %490[1] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %556 = llvm.extractvalue %555[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %557 = llvm.extractvalue %555[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %558 = llvm.mlir.undef : !llvm.struct<()>
      %559 = llvm.extractvalue %490[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %560 = llvm.mlir.constant(7 : i32) : i32
      %561 = llvm.getelementptr %559[%560] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %562 = llvm.ptrtoint %561 : !llvm.ptr to i64
      %563 = llvm.inttoptr %562 : i64 to !llvm.ptr
      llvm.store %372, %563 {alignment = 1 : i64} : i8, !llvm.ptr
      %564 = llvm.mlir.constant(1 : i32) : i32
      llvm.br ^bb6(%51 : i32)
    ^bb6(%565: i32):  // 2 preds: ^bb5, ^bb23
      %566 = llvm.icmp "slt" %565, %564 : i32
      llvm.cond_br %566, ^bb7, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %567 = llvm.extractvalue %53[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %568 = llvm.extractvalue %53[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %569 = llvm.getelementptr %491[%565] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %570 = builtin.unrealized_conversion_cast %569 : !llvm.ptr to !cute.ptr<i8, rmem>
      %571 = builtin.unrealized_conversion_cast %570 : !cute.ptr<i8, rmem> to !llvm.ptr
      %572 = llvm.load %571 : !llvm.ptr -> i8
      %573 = llvm.icmp "ne" %572, %36 : i8
      llvm.cond_br %573, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %574 = builtin.unrealized_conversion_cast %214 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %575 = builtin.unrealized_conversion_cast %219 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %576 = llvm.load %574 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %576, %575 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %577 = llvm.mlir.constant(1 : i32) : i32
      %578 = llvm.getelementptr %569[%577] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %579 = builtin.unrealized_conversion_cast %578 : !llvm.ptr to !cute.ptr<i8, rmem>
      %580 = builtin.unrealized_conversion_cast %579 : !cute.ptr<i8, rmem> to !llvm.ptr
      %581 = llvm.load %580 : !llvm.ptr -> i8
      %582 = llvm.icmp "ne" %581, %36 : i8
      llvm.cond_br %582, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %583 = llvm.mlir.constant(512 : i32) : i32
      %584 = llvm.getelementptr %213[%583] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %585 = builtin.unrealized_conversion_cast %584 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %586 = llvm.mlir.constant(8 : i32) : i32
      %587 = llvm.getelementptr %218[%586] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %588 = builtin.unrealized_conversion_cast %587 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %589 = builtin.unrealized_conversion_cast %585 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %590 = builtin.unrealized_conversion_cast %588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %591 = llvm.load %589 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %591, %590 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %592 = llvm.mlir.constant(2 : i32) : i32
      %593 = llvm.getelementptr %569[%592] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %594 = builtin.unrealized_conversion_cast %593 : !llvm.ptr to !cute.ptr<i8, rmem>
      %595 = builtin.unrealized_conversion_cast %594 : !cute.ptr<i8, rmem> to !llvm.ptr
      %596 = llvm.load %595 : !llvm.ptr -> i8
      %597 = llvm.icmp "ne" %596, %36 : i8
      llvm.cond_br %597, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %598 = llvm.mlir.constant(1024 : i32) : i32
      %599 = llvm.getelementptr %213[%598] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %600 = builtin.unrealized_conversion_cast %599 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %601 = llvm.mlir.constant(16 : i32) : i32
      %602 = llvm.getelementptr %218[%601] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %603 = builtin.unrealized_conversion_cast %602 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %604 = builtin.unrealized_conversion_cast %600 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %605 = builtin.unrealized_conversion_cast %603 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %606 = llvm.load %604 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %606, %605 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %607 = llvm.mlir.constant(3 : i32) : i32
      %608 = llvm.getelementptr %569[%607] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %609 = builtin.unrealized_conversion_cast %608 : !llvm.ptr to !cute.ptr<i8, rmem>
      %610 = builtin.unrealized_conversion_cast %609 : !cute.ptr<i8, rmem> to !llvm.ptr
      %611 = llvm.load %610 : !llvm.ptr -> i8
      %612 = llvm.icmp "ne" %611, %36 : i8
      llvm.cond_br %612, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %613 = llvm.mlir.constant(1536 : i32) : i32
      %614 = llvm.getelementptr %213[%613] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %615 = builtin.unrealized_conversion_cast %614 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %616 = llvm.mlir.constant(24 : i32) : i32
      %617 = llvm.getelementptr %218[%616] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %618 = builtin.unrealized_conversion_cast %617 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %619 = builtin.unrealized_conversion_cast %615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %620 = builtin.unrealized_conversion_cast %618 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %621 = llvm.load %619 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %621, %620 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %622 = llvm.mlir.constant(4 : i32) : i32
      %623 = llvm.getelementptr %569[%622] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %624 = builtin.unrealized_conversion_cast %623 : !llvm.ptr to !cute.ptr<i8, rmem>
      %625 = builtin.unrealized_conversion_cast %624 : !cute.ptr<i8, rmem> to !llvm.ptr
      %626 = llvm.load %625 : !llvm.ptr -> i8
      %627 = llvm.icmp "ne" %626, %36 : i8
      llvm.cond_br %627, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %628 = llvm.mlir.constant(2048 : i32) : i32
      %629 = llvm.getelementptr %213[%628] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %630 = builtin.unrealized_conversion_cast %629 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %631 = llvm.mlir.constant(32 : i32) : i32
      %632 = llvm.getelementptr %218[%631] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %633 = builtin.unrealized_conversion_cast %632 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %634 = builtin.unrealized_conversion_cast %630 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %635 = builtin.unrealized_conversion_cast %633 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %636 = llvm.load %634 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %636, %635 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %637 = llvm.mlir.constant(5 : i32) : i32
      %638 = llvm.getelementptr %569[%637] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %639 = builtin.unrealized_conversion_cast %638 : !llvm.ptr to !cute.ptr<i8, rmem>
      %640 = builtin.unrealized_conversion_cast %639 : !cute.ptr<i8, rmem> to !llvm.ptr
      %641 = llvm.load %640 : !llvm.ptr -> i8
      %642 = llvm.icmp "ne" %641, %36 : i8
      llvm.cond_br %642, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %643 = llvm.mlir.constant(2560 : i32) : i32
      %644 = llvm.getelementptr %213[%643] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %645 = builtin.unrealized_conversion_cast %644 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %646 = llvm.mlir.constant(40 : i32) : i32
      %647 = llvm.getelementptr %218[%646] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %648 = builtin.unrealized_conversion_cast %647 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %649 = builtin.unrealized_conversion_cast %645 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %650 = builtin.unrealized_conversion_cast %648 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %651 = llvm.load %649 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %651, %650 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %652 = llvm.mlir.constant(6 : i32) : i32
      %653 = llvm.getelementptr %569[%652] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %654 = builtin.unrealized_conversion_cast %653 : !llvm.ptr to !cute.ptr<i8, rmem>
      %655 = builtin.unrealized_conversion_cast %654 : !cute.ptr<i8, rmem> to !llvm.ptr
      %656 = llvm.load %655 : !llvm.ptr -> i8
      %657 = llvm.icmp "ne" %656, %36 : i8
      llvm.cond_br %657, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %658 = llvm.mlir.constant(3072 : i32) : i32
      %659 = llvm.getelementptr %213[%658] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %660 = builtin.unrealized_conversion_cast %659 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %661 = llvm.mlir.constant(48 : i32) : i32
      %662 = llvm.getelementptr %218[%661] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %663 = builtin.unrealized_conversion_cast %662 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %664 = builtin.unrealized_conversion_cast %660 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %665 = builtin.unrealized_conversion_cast %663 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %666 = llvm.load %664 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %666, %665 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %667 = llvm.mlir.constant(7 : i32) : i32
      %668 = llvm.getelementptr %569[%667] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %669 = builtin.unrealized_conversion_cast %668 : !llvm.ptr to !cute.ptr<i8, rmem>
      %670 = builtin.unrealized_conversion_cast %669 : !cute.ptr<i8, rmem> to !llvm.ptr
      %671 = llvm.load %670 : !llvm.ptr -> i8
      %672 = llvm.icmp "ne" %671, %36 : i8
      llvm.cond_br %672, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %673 = llvm.mlir.constant(3584 : i32) : i32
      %674 = llvm.getelementptr %213[%673] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %675 = builtin.unrealized_conversion_cast %674 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %676 = llvm.mlir.constant(56 : i32) : i32
      %677 = llvm.getelementptr %218[%676] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %678 = builtin.unrealized_conversion_cast %677 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %679 = builtin.unrealized_conversion_cast %675 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %680 = builtin.unrealized_conversion_cast %678 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %681 = llvm.load %679 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %681, %680 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %682 = llvm.add %565, %50 : i32
      llvm.br ^bb6(%682 : i32)
    ^bb24:  // pred: ^bb6
      nvvm.cp.async.wait.group 0
      %683 = llvm.extractvalue %207[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %684 = llvm.mlir.constant(8 : i32) : i32
      llvm.br ^bb25(%51 : i32)
    ^bb25(%685: i32):  // 2 preds: ^bb24, ^bb26
      %686 = llvm.icmp "slt" %685, %684 : i32
      llvm.cond_br %686, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %687 = llvm.extractvalue %28[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %688 = llvm.extractvalue %28[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %689 = llvm.mlir.constant(512 : i32) : i32
      %690 = llvm.mul %685, %689 : i32
      %691 = llvm.getelementptr %193[%690] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %692 = builtin.unrealized_conversion_cast %691 : !llvm.ptr<3> to !cute.ptr<bf16, smem, align<16>>
      %693 = llvm.extractvalue %27[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %694 = llvm.extractvalue %27[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %695 = llvm.mlir.constant(8 : i32) : i32
      %696 = llvm.mul %685, %695 : i32
      %697 = llvm.getelementptr %683[%696] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %698 = builtin.unrealized_conversion_cast %697 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %699 = builtin.unrealized_conversion_cast %692 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %700 = builtin.unrealized_conversion_cast %698 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %701 = llvm.load %699 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %701, %700 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %702 = llvm.add %685, %50 : i32
      llvm.br ^bb25(%702 : i32)
    ^bb27:  // pred: ^bb25
      %703 = llvm.mlir.poison : !llvm.array<1 x vector<64xbf16>>
      %704 = builtin.unrealized_conversion_cast %703 : !llvm.array<1 x vector<64xbf16>> to vector<1x64xbf16>
      %705 = llvm.extractvalue %207[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %706 = llvm.getelementptr %705[0] : (!llvm.ptr) -> !llvm.ptr, bf16
      %707 = llvm.load %706 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %708 = vector.insert %707, %704 [0] : vector<64xbf16> into vector<1x64xbf16>
      %709 = vector.shape_cast %708 : vector<1x64xbf16> to vector<64xbf16>
      %710 = llvm.fpext %709 : vector<64xbf16> to vector<64xf32>
      %711 = llvm.fmul %710, %710 : vector<64xf32>
      %712 = vector.reduction <add>, %711, %26 : vector<64xf32> into f32
      %713 = nvvm.shfl.sync  bfly %25, %712, %24, %23 : f32 -> f32
      %714 = llvm.fadd %713, %712 : f32
      %715 = nvvm.shfl.sync  bfly %25, %714, %71, %23 : f32 -> f32
      %716 = llvm.fadd %714, %715 : f32
      %717 = nvvm.shfl.sync  bfly %25, %716, %22, %23 : f32 -> f32
      %718 = llvm.fadd %716, %717 : f32
      %719 = nvvm.shfl.sync  bfly %25, %718, %75, %23 : f32 -> f32
      %720 = llvm.fadd %718, %719 : f32
      %721 = nvvm.shfl.sync  bfly %25, %720, %50, %23 : f32 -> f32
      %722 = llvm.fadd %720, %721 : f32
      %723 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %724 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %725 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %726 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %727 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %728 = llvm.mul %724, %726 : i32
      %729 = llvm.add %81, %728 : i32
      %730 = llvm.mul %725, %726 : i32
      %731 = llvm.mul %730, %727 : i32
      %732 = llvm.add %729, %731 : i32
      %733 = llvm.sdiv %732, %21 : i32
      %734 = llvm.mul %733, %21 : i32
      %735 = llvm.icmp "ne" %732, %734 : i32
      %736 = llvm.mlir.constant(0 : i32) : i32
      %737 = llvm.icmp "slt" %732, %736 : i32
      %738 = llvm.mlir.constant(false) : i1
      %739 = llvm.icmp "ne" %737, %738 : i1
      %740 = llvm.and %735, %739 : i1
      %741 = llvm.mlir.constant(-1 : i32) : i32
      %742 = llvm.add %733, %741 : i32
      %743 = llvm.select %740, %742, %733 : i1, i32
      %744 = llvm.sdiv %743, %75 : i32
      %745 = llvm.mul %744, %75 : i32
      %746 = llvm.icmp "ne" %743, %745 : i32
      %747 = llvm.mlir.constant(0 : i32) : i32
      %748 = llvm.icmp "slt" %743, %747 : i32
      %749 = llvm.mlir.constant(false) : i1
      %750 = llvm.icmp "ne" %748, %749 : i1
      %751 = llvm.and %746, %750 : i1
      %752 = llvm.mlir.constant(-1 : i32) : i32
      %753 = llvm.add %744, %752 : i32
      %754 = llvm.select %751, %753, %744 : i1, i32
      %755 = llvm.srem %743, %75 : i32
      %756 = llvm.icmp "eq" %723, %51 : i32
      llvm.cond_br %756, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %757 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %758 = llvm.insertvalue %754, %757[0] : !llvm.struct<(i32, i32)> 
      %759 = llvm.insertvalue %755, %758[1] : !llvm.struct<(i32, i32)> 
      %760 = llvm.extractvalue %92[1] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %761 = llvm.extractvalue %760[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %762 = llvm.extractvalue %760[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %763 = llvm.extractvalue %759[0] : !llvm.struct<(i32, i32)> 
      %764 = llvm.extractvalue %759[1] : !llvm.struct<(i32, i32)> 
      %765 = llvm.mlir.constant(2 : i32) : i32
      %766 = llvm.mul %764, %765 : i32
      %767 = llvm.add %763, %766 : i32
      %768 = llvm.extractvalue %92[0] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %769 = llvm.getelementptr %768[%767] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
      %770 = llvm.ptrtoint %769 : !llvm.ptr<3> to i64
      %771 = llvm.inttoptr %770 : i64 to !llvm.ptr<3>
      llvm.store %722, %771 {alignment = 4 : i64} : f32, !llvm.ptr<3>
      llvm.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      nvvm.barrier
      %772 = llvm.icmp "slt" %723, %75 : i32
      llvm.cond_br %772, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %773 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %774 = llvm.insertvalue %754, %773[0] : !llvm.struct<(i32, i32)> 
      %775 = llvm.insertvalue %723, %774[1] : !llvm.struct<(i32, i32)> 
      %776 = llvm.extractvalue %92[1] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %777 = llvm.extractvalue %776[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %778 = llvm.extractvalue %776[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %779 = llvm.extractvalue %775[0] : !llvm.struct<(i32, i32)> 
      %780 = llvm.extractvalue %775[1] : !llvm.struct<(i32, i32)> 
      %781 = llvm.mlir.constant(2 : i32) : i32
      %782 = llvm.mul %780, %781 : i32
      %783 = llvm.add %779, %782 : i32
      %784 = llvm.extractvalue %92[0] : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> 
      %785 = llvm.getelementptr %784[%783] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
      %786 = llvm.ptrtoint %785 : !llvm.ptr<3> to i64
      %787 = llvm.inttoptr %786 : i64 to !llvm.ptr<3>
      %788 = llvm.load %787 {alignment = 4 : i64} : !llvm.ptr<3> -> f32
      llvm.br ^bb32(%788 : f32)
    ^bb31:  // pred: ^bb29
      llvm.br ^bb32(%26 : f32)
    ^bb32(%789: f32):  // 2 preds: ^bb30, ^bb31
      llvm.br ^bb33
    ^bb33:  // pred: ^bb32
      %790 = nvvm.shfl.sync  bfly %25, %789, %24, %23 : f32 -> f32
      %791 = llvm.fadd %789, %790 : f32
      %792 = nvvm.shfl.sync  bfly %25, %791, %71, %23 : f32 -> f32
      %793 = llvm.fadd %791, %792 : f32
      %794 = nvvm.shfl.sync  bfly %25, %793, %22, %23 : f32 -> f32
      %795 = llvm.fadd %793, %794 : f32
      %796 = nvvm.shfl.sync  bfly %25, %795, %75, %23 : f32 -> f32
      %797 = llvm.fadd %795, %796 : f32
      %798 = nvvm.shfl.sync  bfly %25, %797, %50, %23 : f32 -> f32
      %799 = llvm.fadd %797, %798 : f32
      %800 = llvm.fdiv %799, %20 : f32
      %801 = llvm.fadd %800, %arg3 : f32
      %802 = math.rsqrt %801 fastmath<fast> : f32
      nvvm.barrier
      llvm.br ^bb34(%51 : i32)
    ^bb34(%803: i32):  // 2 preds: ^bb33, ^bb35
      %804 = llvm.icmp "slt" %803, %684 : i32
      llvm.cond_br %804, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %805 = llvm.extractvalue %28[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %806 = llvm.extractvalue %28[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %807 = llvm.mlir.constant(512 : i32) : i32
      %808 = llvm.mul %803, %807 : i32
      %809 = llvm.getelementptr %193[%808] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %810 = builtin.unrealized_conversion_cast %809 : !llvm.ptr<3> to !cute.ptr<bf16, smem, align<16>>
      %811 = llvm.extractvalue %27[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %812 = llvm.extractvalue %27[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %813 = llvm.mlir.constant(8 : i32) : i32
      %814 = llvm.mul %803, %813 : i32
      %815 = llvm.getelementptr %683[%814] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %816 = builtin.unrealized_conversion_cast %815 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %817 = builtin.unrealized_conversion_cast %810 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %818 = builtin.unrealized_conversion_cast %816 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %819 = llvm.load %817 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %819, %818 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %820 = llvm.add %803, %50 : i32
      llvm.br ^bb34(%820 : i32)
    ^bb36:  // pred: ^bb34
      %821 = llvm.mlir.poison : !llvm.array<1 x vector<64xbf16>>
      %822 = builtin.unrealized_conversion_cast %821 : !llvm.array<1 x vector<64xbf16>> to vector<1x64xbf16>
      %823 = llvm.extractvalue %207[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %824 = llvm.getelementptr %823[0] : (!llvm.ptr) -> !llvm.ptr, bf16
      %825 = llvm.load %824 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %826 = vector.insert %825, %822 [0] : vector<64xbf16> into vector<1x64xbf16>
      %827 = vector.shape_cast %826 : vector<1x64xbf16> to vector<64xbf16>
      %828 = llvm.fpext %827 : vector<64xbf16> to vector<64xf32>
      %829 = vector.broadcast %802 : f32 to vector<64xf32>
      %830 = llvm.fmul %828, %829 : vector<64xf32>
      %831 = llvm.mlir.poison : !llvm.array<1 x vector<64xbf16>>
      %832 = builtin.unrealized_conversion_cast %831 : !llvm.array<1 x vector<64xbf16>> to vector<1x64xbf16>
      %833 = llvm.extractvalue %223[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %834 = llvm.getelementptr %833[0] : (!llvm.ptr) -> !llvm.ptr, bf16
      %835 = llvm.load %834 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %836 = vector.insert %835, %832 [0] : vector<64xbf16> into vector<1x64xbf16>
      %837 = vector.shape_cast %836 : vector<1x64xbf16> to vector<64xbf16>
      %838 = llvm.fpext %837 : vector<64xbf16> to vector<64xf32>
      %839 = llvm.fmul %830, %838 : vector<64xf32>
      %840 = llvm.fptrunc %839 : vector<64xf32> to vector<64xbf16>
      %841 = vector.shape_cast %840 : vector<64xbf16> to vector<1x64xbf16>
      %842 = llvm.extractvalue %210[0] : !llvm.struct<(ptr, struct<(struct<()>, struct<()>)>)> 
      %843 = vector.extract %841[0] : vector<64xbf16> from vector<1x64xbf16>
      %844 = llvm.getelementptr %842[0] : (!llvm.ptr) -> !llvm.ptr, bf16
      llvm.store %843, %844 {alignment = 32 : i64} : vector<64xbf16>, !llvm.ptr
      llvm.cond_br %382, ^bb37, ^bb57
    ^bb37:  // pred: ^bb36
      llvm.br ^bb38(%51 : i32)
    ^bb38(%845: i32):  // 2 preds: ^bb37, ^bb55
      %846 = llvm.icmp "slt" %845, %564 : i32
      llvm.cond_br %846, ^bb39, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %847 = llvm.extractvalue %53[0] : !llvm.struct<(struct<()>, struct<()>)> 
      %848 = llvm.extractvalue %53[1] : !llvm.struct<(struct<()>, struct<()>)> 
      %849 = llvm.getelementptr %227[%845] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %850 = builtin.unrealized_conversion_cast %849 : !llvm.ptr to !cute.ptr<i8, rmem>
      %851 = builtin.unrealized_conversion_cast %850 : !cute.ptr<i8, rmem> to !llvm.ptr
      %852 = llvm.load %851 : !llvm.ptr -> i8
      %853 = llvm.icmp "ne" %852, %36 : i8
      llvm.cond_br %853, ^bb40, ^bb41
    ^bb40:  // pred: ^bb39
      %854 = builtin.unrealized_conversion_cast %212 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %855 = builtin.unrealized_conversion_cast %195 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %856 = llvm.load %854 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %856, %855 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb41
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %857 = llvm.mlir.constant(1 : i32) : i32
      %858 = llvm.getelementptr %849[%857] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %859 = builtin.unrealized_conversion_cast %858 : !llvm.ptr to !cute.ptr<i8, rmem>
      %860 = builtin.unrealized_conversion_cast %859 : !cute.ptr<i8, rmem> to !llvm.ptr
      %861 = llvm.load %860 : !llvm.ptr -> i8
      %862 = llvm.icmp "ne" %861, %36 : i8
      llvm.cond_br %862, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %863 = llvm.mlir.constant(8 : i32) : i32
      %864 = llvm.getelementptr %211[%863] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %865 = builtin.unrealized_conversion_cast %864 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %866 = llvm.mlir.constant(512 : i32) : i32
      %867 = llvm.getelementptr %194[%866] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %868 = builtin.unrealized_conversion_cast %867 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %869 = builtin.unrealized_conversion_cast %865 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %870 = builtin.unrealized_conversion_cast %868 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %871 = llvm.load %869 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %871, %870 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %872 = llvm.mlir.constant(2 : i32) : i32
      %873 = llvm.getelementptr %849[%872] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %874 = builtin.unrealized_conversion_cast %873 : !llvm.ptr to !cute.ptr<i8, rmem>
      %875 = builtin.unrealized_conversion_cast %874 : !cute.ptr<i8, rmem> to !llvm.ptr
      %876 = llvm.load %875 : !llvm.ptr -> i8
      %877 = llvm.icmp "ne" %876, %36 : i8
      llvm.cond_br %877, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %878 = llvm.mlir.constant(16 : i32) : i32
      %879 = llvm.getelementptr %211[%878] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %880 = builtin.unrealized_conversion_cast %879 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %881 = llvm.mlir.constant(1024 : i32) : i32
      %882 = llvm.getelementptr %194[%881] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %883 = builtin.unrealized_conversion_cast %882 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %884 = builtin.unrealized_conversion_cast %880 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %885 = builtin.unrealized_conversion_cast %883 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %886 = llvm.load %884 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %886, %885 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %887 = llvm.mlir.constant(3 : i32) : i32
      %888 = llvm.getelementptr %849[%887] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %889 = builtin.unrealized_conversion_cast %888 : !llvm.ptr to !cute.ptr<i8, rmem>
      %890 = builtin.unrealized_conversion_cast %889 : !cute.ptr<i8, rmem> to !llvm.ptr
      %891 = llvm.load %890 : !llvm.ptr -> i8
      %892 = llvm.icmp "ne" %891, %36 : i8
      llvm.cond_br %892, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %893 = llvm.mlir.constant(24 : i32) : i32
      %894 = llvm.getelementptr %211[%893] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %895 = builtin.unrealized_conversion_cast %894 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %896 = llvm.mlir.constant(1536 : i32) : i32
      %897 = llvm.getelementptr %194[%896] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %898 = builtin.unrealized_conversion_cast %897 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %899 = builtin.unrealized_conversion_cast %895 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %900 = builtin.unrealized_conversion_cast %898 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %901 = llvm.load %899 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %901, %900 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %902 = llvm.mlir.constant(4 : i32) : i32
      %903 = llvm.getelementptr %849[%902] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %904 = builtin.unrealized_conversion_cast %903 : !llvm.ptr to !cute.ptr<i8, rmem>
      %905 = builtin.unrealized_conversion_cast %904 : !cute.ptr<i8, rmem> to !llvm.ptr
      %906 = llvm.load %905 : !llvm.ptr -> i8
      %907 = llvm.icmp "ne" %906, %36 : i8
      llvm.cond_br %907, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %908 = llvm.mlir.constant(32 : i32) : i32
      %909 = llvm.getelementptr %211[%908] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %910 = builtin.unrealized_conversion_cast %909 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %911 = llvm.mlir.constant(2048 : i32) : i32
      %912 = llvm.getelementptr %194[%911] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %913 = builtin.unrealized_conversion_cast %912 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %914 = builtin.unrealized_conversion_cast %910 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %915 = builtin.unrealized_conversion_cast %913 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %916 = llvm.load %914 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %916, %915 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %917 = llvm.mlir.constant(5 : i32) : i32
      %918 = llvm.getelementptr %849[%917] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %919 = builtin.unrealized_conversion_cast %918 : !llvm.ptr to !cute.ptr<i8, rmem>
      %920 = builtin.unrealized_conversion_cast %919 : !cute.ptr<i8, rmem> to !llvm.ptr
      %921 = llvm.load %920 : !llvm.ptr -> i8
      %922 = llvm.icmp "ne" %921, %36 : i8
      llvm.cond_br %922, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %923 = llvm.mlir.constant(40 : i32) : i32
      %924 = llvm.getelementptr %211[%923] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %925 = builtin.unrealized_conversion_cast %924 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %926 = llvm.mlir.constant(2560 : i32) : i32
      %927 = llvm.getelementptr %194[%926] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %928 = builtin.unrealized_conversion_cast %927 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %929 = builtin.unrealized_conversion_cast %925 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %930 = builtin.unrealized_conversion_cast %928 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %931 = llvm.load %929 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %931, %930 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %932 = llvm.mlir.constant(6 : i32) : i32
      %933 = llvm.getelementptr %849[%932] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %934 = builtin.unrealized_conversion_cast %933 : !llvm.ptr to !cute.ptr<i8, rmem>
      %935 = builtin.unrealized_conversion_cast %934 : !cute.ptr<i8, rmem> to !llvm.ptr
      %936 = llvm.load %935 : !llvm.ptr -> i8
      %937 = llvm.icmp "ne" %936, %36 : i8
      llvm.cond_br %937, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %938 = llvm.mlir.constant(48 : i32) : i32
      %939 = llvm.getelementptr %211[%938] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %940 = builtin.unrealized_conversion_cast %939 : !llvm.ptr to !cute.ptr<bf16, rmem, align<32>>
      %941 = llvm.mlir.constant(3072 : i32) : i32
      %942 = llvm.getelementptr %194[%941] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %943 = builtin.unrealized_conversion_cast %942 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %944 = builtin.unrealized_conversion_cast %940 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %945 = builtin.unrealized_conversion_cast %943 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %946 = llvm.load %944 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %946, %945 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %947 = llvm.mlir.constant(7 : i32) : i32
      %948 = llvm.getelementptr %849[%947] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %949 = builtin.unrealized_conversion_cast %948 : !llvm.ptr to !cute.ptr<i8, rmem>
      %950 = builtin.unrealized_conversion_cast %949 : !cute.ptr<i8, rmem> to !llvm.ptr
      %951 = llvm.load %950 : !llvm.ptr -> i8
      %952 = llvm.icmp "ne" %951, %36 : i8
      llvm.cond_br %952, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %953 = llvm.mlir.constant(56 : i32) : i32
      %954 = llvm.getelementptr %211[%953] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %955 = builtin.unrealized_conversion_cast %954 : !llvm.ptr to !cute.ptr<bf16, rmem, align<16>>
      %956 = llvm.mlir.constant(3584 : i32) : i32
      %957 = llvm.getelementptr %194[%956] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %958 = builtin.unrealized_conversion_cast %957 : !llvm.ptr<1> to !cute.ptr<bf16, gmem, align<16>>
      %959 = builtin.unrealized_conversion_cast %955 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %960 = builtin.unrealized_conversion_cast %958 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %961 = llvm.load %959 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %961, %960 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %962 = llvm.add %845, %50 : i32
      llvm.br ^bb38(%962 : i32)
    ^bb56:  // pred: ^bb38
      llvm.br ^bb57
    ^bb57:  // 2 preds: ^bb36, ^bb56
      llvm.return
    }
  }
  llvm.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg1: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg2: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(16400 : i64) : i64
    %1 = llvm.mlir.constant(0 : i32) : i32
    %2 = llvm.mlir.constant(1 : i32) : i32
    %3 = llvm.mlir.constant(128 : i32) : i32
    %4 = llvm.mlir.constant(2 : i32) : i32
    %5 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
    %6 = llvm.mlir.poison : !llvm.struct<()>
    %7 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
    %8 = llvm.insertvalue %arg3, %7[0] : !llvm.struct<(i32, struct<()>)> 
    %9 = llvm.insertvalue %6, %8[1] : !llvm.struct<(i32, struct<()>)> 
    %10 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %11 = llvm.insertvalue %arg0, %10[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %12 = llvm.insertvalue %9, %11[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %13 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %14 = llvm.insertvalue %arg2, %13[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %15 = llvm.insertvalue %9, %14[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %16 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>
    %17 = llvm.insertvalue %arg1, %16[0] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
    %18 = llvm.insertvalue %5, %17[1] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
    %19 = llvm.mlir.constant(1 : i32) : i32
    %20 = llvm.mlir.constant(0 : i32) : i32
    %21 = llvm.mlir.constant(-1 : i32) : i32
    %22 = llvm.mlir.constant(true) : i1
    %23 = llvm.select %22, %21, %19 : i1, i32
    %24 = llvm.add %23, %arg3 : i32
    %25 = llvm.sdiv %24, %4 : i32
    %26 = llvm.add %25, %19 : i32
    %27 = llvm.sub %20, %arg3 : i32
    %28 = llvm.sdiv %27, %4 : i32
    %29 = llvm.sub %20, %28 : i32
    %30 = llvm.icmp "slt" %arg3, %20 : i32
    %31 = llvm.icmp "sgt" %arg3, %20 : i32
    %32 = llvm.mlir.constant(false) : i1
    %33 = llvm.mlir.constant(true) : i1
    %34 = llvm.and %30, %32 : i1
    %35 = llvm.and %31, %33 : i1
    %36 = llvm.or %34, %35 : i1
    %37 = llvm.select %36, %26, %29 : i1, i32
    %38 = llvm.mlir.constant(1 : i32) : i32
    %39 = llvm.alloca %38 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %40 = llvm.alloca %38 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %41 = llvm.getelementptr %39[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %40, %41 : !llvm.ptr, !llvm.ptr
    %42 = llvm.getelementptr %39[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %42 : i32, !llvm.ptr
    %43 = llvm.getelementptr %39[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %43 : i32, !llvm.ptr
    %44 = llvm.getelementptr %39[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %44 : i32, !llvm.ptr
    %45 = llvm.getelementptr %39[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %45 : i64, !llvm.ptr
    %46 = llvm.getelementptr %39[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %37, %46 : i32, !llvm.ptr
    %47 = llvm.getelementptr %39[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %47 : i32, !llvm.ptr
    %48 = llvm.getelementptr %39[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %48 : i32, !llvm.ptr
    %49 = llvm.getelementptr %39[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    %50 = llvm.mlir.constant(0 : i32) : i32
    llvm.store %50, %49 : i32, !llvm.ptr
    %51 = llvm.getelementptr %39[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %arg5, %51 : !llvm.ptr, !llvm.ptr
    %52 = llvm.alloca %38 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %53 = llvm.getelementptr %52[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %39, %53 : !llvm.ptr, !llvm.ptr
    %54 = builtin.unrealized_conversion_cast %52 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %55 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%54> (%12, %18, %15, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32) -> !cuda.result
    %56 = builtin.unrealized_conversion_cast %55 : !cuda.result to i32
    cuda.return_if_error %56 : i32
    llvm.return %1 : i32
  }
  llvm.func @_mlir_ciface_cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg1: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg2: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0, %arg1, %arg2, %arg3, %arg4, %arg5) : (!llvm.ptr<1>, !llvm.ptr<1>, !llvm.ptr<1>, i32, f32, !llvm.ptr) -> i32
    llvm.return %0 : i32
  }
}
