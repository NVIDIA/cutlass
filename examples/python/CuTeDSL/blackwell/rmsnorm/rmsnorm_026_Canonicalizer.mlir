#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (ptr, ...)>, linkage = #llvm.linkage<external>, sym_name = "printf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<4 x i8>, linkage = #llvm.linkage<internal>, sym_name = "%s\0A", value = "%s\0A\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<72 x i8>, linkage = #llvm.linkage<internal>, sym_name = "ERROR: Reached max number of attributes, unable to add more attributes.", value = "ERROR: Reached max number of attributes, unable to add more attributes.\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "gpu.module"() <{sym_name = "kernels"}> ({
    "llvm.mlir.global"() <{addr_space = 3 : i32, alignment = 1024 : i64, dso_local, global_type = !llvm.array<0 x i8>, linkage = #llvm.linkage<external>, sym_name = "__dynamic_shmem__0", visibility_ = 0 : i64}> ({
    }) : () -> ()
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0", visibility_ = 0 : i64}> ({
    ^bb0(%arg12: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg13: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg14: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg15: f32):
      %100 = "llvm.mlir.constant"() <{value = 3584 : i32}> : () -> i32
      %101 = "llvm.mlir.constant"() <{value = 3072 : i32}> : () -> i32
      %102 = "llvm.mlir.constant"() <{value = 2560 : i32}> : () -> i32
      %103 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
      %104 = "llvm.mlir.constant"() <{value = 1536 : i32}> : () -> i32
      %105 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
      %106 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
      %107 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
      %108 = "llvm.mlir.constant"() <{value = false}> : () -> i1
      %109 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
      %110 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
      %111 = "llvm.mlir.constant"() <{value = 4096 : i32}> : () -> i32
      %112 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %113 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %114 = "llvm.mlir.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %115 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
      %116 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      %117 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
      %118 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
      %119 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
      %120 = "llvm.mlir.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %121 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
      %122 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
      %123 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
      %124 = "llvm.alloca"(%122) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %125 = "llvm.alloca"(%122) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %126 = "llvm.alloca"(%121) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %127 = "llvm.alloca"(%121) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %128 = "llvm.alloca"(%121) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %129 = "llvm.extractvalue"(%arg13) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>) -> !llvm.ptr<1>
      %130 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %131 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %132 = "llvm.extractvalue"(%arg12) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.struct<(i32, struct<()>)>
      %133 = "llvm.extractvalue"(%132) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>) -> i32
      %134 = "llvm.getelementptr"(%109) <{elem_type = i8, rawConstantIndices = array<i32: 16384>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %135 = "llvm.mul"(%131, %107) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %136 = "llvm.extractvalue"(%arg12) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %137 = "llvm.getelementptr"(%136, %135) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %138 = "llvm.mul"(%131, %107) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %139 = "llvm.extractvalue"(%arg14) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %140 = "llvm.getelementptr"(%139, %138) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %141 = "llvm.mul"(%131, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %142 = "llvm.sdiv"(%130, %121) : (i32, i32) -> i32
      %143 = "llvm.srem"(%130, %121) : (i32, i32) -> i32
      %144 = "llvm.mul"(%143, %122) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %145 = "llvm.mul"(%142, %111) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %146 = "llvm.add"(%144, %145) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %147 = "llvm.getelementptr"(%137, %146) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %148 = "llvm.getelementptr"(%109, %146) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %149 = "llvm.getelementptr"(%140, %146) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %150 = "llvm.add"(%141, %142) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %151 = "llvm.getelementptr"(%129, %144) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %152 = "llvm.icmp"(%144, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %153 = "llvm.zext"(%152) : (i1) -> i8
      %154 = "llvm.ptrtoint"(%125) : (!llvm.ptr) -> i64
      %155 = "llvm.inttoptr"(%154) : (i64) -> !llvm.ptr
      "llvm.store"(%153, %155) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %156 = "llvm.add"(%144, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %157 = "llvm.icmp"(%156, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %158 = "llvm.zext"(%157) : (i1) -> i8
      %159 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %160 = "llvm.ptrtoint"(%159) : (!llvm.ptr) -> i64
      %161 = "llvm.inttoptr"(%160) : (i64) -> !llvm.ptr
      "llvm.store"(%158, %161) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %162 = "llvm.add"(%144, %105) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %163 = "llvm.icmp"(%162, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %164 = "llvm.zext"(%163) : (i1) -> i8
      %165 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %166 = "llvm.ptrtoint"(%165) : (!llvm.ptr) -> i64
      %167 = "llvm.inttoptr"(%166) : (i64) -> !llvm.ptr
      "llvm.store"(%164, %167) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %168 = "llvm.add"(%144, %104) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %169 = "llvm.icmp"(%168, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %170 = "llvm.zext"(%169) : (i1) -> i8
      %171 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %172 = "llvm.ptrtoint"(%171) : (!llvm.ptr) -> i64
      %173 = "llvm.inttoptr"(%172) : (i64) -> !llvm.ptr
      "llvm.store"(%170, %173) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %174 = "llvm.add"(%144, %103) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %175 = "llvm.icmp"(%174, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %176 = "llvm.zext"(%175) : (i1) -> i8
      %177 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %178 = "llvm.ptrtoint"(%177) : (!llvm.ptr) -> i64
      %179 = "llvm.inttoptr"(%178) : (i64) -> !llvm.ptr
      "llvm.store"(%176, %179) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %180 = "llvm.add"(%144, %102) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %181 = "llvm.icmp"(%180, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %182 = "llvm.zext"(%181) : (i1) -> i8
      %183 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %184 = "llvm.ptrtoint"(%183) : (!llvm.ptr) -> i64
      %185 = "llvm.inttoptr"(%184) : (i64) -> !llvm.ptr
      "llvm.store"(%182, %185) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %186 = "llvm.add"(%144, %101) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %187 = "llvm.icmp"(%186, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %188 = "llvm.zext"(%187) : (i1) -> i8
      %189 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %190 = "llvm.ptrtoint"(%189) : (!llvm.ptr) -> i64
      %191 = "llvm.inttoptr"(%190) : (i64) -> !llvm.ptr
      "llvm.store"(%188, %191) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %192 = "llvm.add"(%144, %100) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %193 = "llvm.icmp"(%192, %111) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %194 = "llvm.zext"(%193) : (i1) -> i8
      %195 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %196 = "llvm.ptrtoint"(%195) : (!llvm.ptr) -> i64
      %197 = "llvm.inttoptr"(%196) : (i64) -> !llvm.ptr
      "llvm.store"(%194, %197) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %198 = "llvm.icmp"(%150, %133) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%198)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %199 = "llvm.load"(%125) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %200 = "llvm.trunc"(%199) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %201 = "llvm.select"(%200, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%148, %147, %201) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %202 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %203 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %204 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %205 = "llvm.load"(%204) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %206 = "llvm.trunc"(%205) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %207 = "llvm.select"(%206, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%203, %202, %207) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %208 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %209 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %210 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %211 = "llvm.load"(%210) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %212 = "llvm.trunc"(%211) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %213 = "llvm.select"(%212, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%209, %208, %213) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %214 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %215 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %216 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %217 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %218 = "llvm.trunc"(%217) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %219 = "llvm.select"(%218, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%215, %214, %219) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %220 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %221 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %222 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %223 = "llvm.load"(%222) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %224 = "llvm.trunc"(%223) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %225 = "llvm.select"(%224, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%221, %220, %225) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %226 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %227 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %228 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %229 = "llvm.load"(%228) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %230 = "llvm.trunc"(%229) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %231 = "llvm.select"(%230, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%227, %226, %231) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %232 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %233 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %234 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %235 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %236 = "llvm.trunc"(%235) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %237 = "llvm.select"(%236, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%233, %232, %237) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      %238 = "llvm.getelementptr"(%147) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %239 = "llvm.getelementptr"(%148) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %240 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %241 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %242 = "llvm.trunc"(%241) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %243 = "llvm.select"(%242, %116, %112) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "nvvm.cp.async.shared.global"(%239, %238, %243) <{modifier = #nvvm<load_cache_modifier ca>, size = 16 : i32}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32) -> ()
      "llvm.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "nvvm.cp.async.commit.group"() : () -> ()
      %244 = "llvm.ptrtoint"(%124) : (!llvm.ptr) -> i64
      %245 = "llvm.inttoptr"(%244) : (i64) -> !llvm.ptr
      "llvm.store"(%153, %245) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %246 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %247 = "llvm.ptrtoint"(%246) : (!llvm.ptr) -> i64
      %248 = "llvm.inttoptr"(%247) : (i64) -> !llvm.ptr
      "llvm.store"(%158, %248) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %249 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %250 = "llvm.ptrtoint"(%249) : (!llvm.ptr) -> i64
      %251 = "llvm.inttoptr"(%250) : (i64) -> !llvm.ptr
      "llvm.store"(%164, %251) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %252 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %253 = "llvm.ptrtoint"(%252) : (!llvm.ptr) -> i64
      %254 = "llvm.inttoptr"(%253) : (i64) -> !llvm.ptr
      "llvm.store"(%170, %254) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %255 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %256 = "llvm.ptrtoint"(%255) : (!llvm.ptr) -> i64
      %257 = "llvm.inttoptr"(%256) : (i64) -> !llvm.ptr
      "llvm.store"(%176, %257) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %258 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %259 = "llvm.ptrtoint"(%258) : (!llvm.ptr) -> i64
      %260 = "llvm.inttoptr"(%259) : (i64) -> !llvm.ptr
      "llvm.store"(%182, %260) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %261 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %262 = "llvm.ptrtoint"(%261) : (!llvm.ptr) -> i64
      %263 = "llvm.inttoptr"(%262) : (i64) -> !llvm.ptr
      "llvm.store"(%188, %263) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %264 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %265 = "llvm.ptrtoint"(%264) : (!llvm.ptr) -> i64
      %266 = "llvm.inttoptr"(%265) : (i64) -> !llvm.ptr
      "llvm.store"(%194, %266) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %267 = "llvm.load"(%124) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %268 = "llvm.icmp"(%267, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%268)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      %269 = "llvm.load"(%151) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%269, %126) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %270 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %271 = "llvm.load"(%270) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %272 = "llvm.icmp"(%271, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%272)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %273 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %274 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %275 = "llvm.load"(%273) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%275, %274) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %276 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %277 = "llvm.load"(%276) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %278 = "llvm.icmp"(%277, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%278)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %279 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %280 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %281 = "llvm.load"(%279) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%281, %280) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %282 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %283 = "llvm.load"(%282) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %284 = "llvm.icmp"(%283, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%284)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %285 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %286 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %287 = "llvm.load"(%285) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%287, %286) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %288 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %289 = "llvm.load"(%288) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %290 = "llvm.icmp"(%289, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%290)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %291 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %292 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %293 = "llvm.load"(%291) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%293, %292) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %294 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %295 = "llvm.load"(%294) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %296 = "llvm.icmp"(%295, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%296)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %297 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %298 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %299 = "llvm.load"(%297) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%299, %298) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb14] : () -> ()
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %300 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %301 = "llvm.load"(%300) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %302 = "llvm.icmp"(%301, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%302)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %303 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %304 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %305 = "llvm.load"(%303) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%305, %304) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb16] : () -> ()
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %306 = "llvm.getelementptr"(%124) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %307 = "llvm.load"(%306) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %308 = "llvm.icmp"(%307, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%308)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %309 = "llvm.getelementptr"(%151) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %310 = "llvm.getelementptr"(%126) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %311 = "llvm.load"(%309) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%311, %310) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb18] : () -> ()
    ^bb18:  // 2 preds: ^bb16, ^bb17
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      "llvm.br"(%112)[^bb19] : (i32) -> ()
    ^bb19(%312: i32):  // 2 preds: ^bb18, ^bb20
      %313 = "llvm.icmp"(%312, %122) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%313)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %314 = "llvm.mul"(%312, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %315 = "llvm.getelementptr"(%148, %314) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %316 = "llvm.mul"(%312, %122) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %317 = "llvm.getelementptr"(%128, %316) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %318 = "llvm.load"(%315) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%318, %317) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %319 = "llvm.add"(%312, %123) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%319)[^bb19] : (i32) -> ()
    ^bb21:  // pred: ^bb19
      %320 = "llvm.load"(%128) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %321 = "llvm.fpext"(%320) : (vector<64xbf16>) -> vector<64xf32>
      %322 = "llvm.fmul"(%321, %321) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %323 = "vector.reduction"(%322, %114) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %324 = "nvvm.shfl.sync"(%115, %323, %116, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %325 = "llvm.fadd"(%324, %323) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %326 = "nvvm.shfl.sync"(%115, %325, %122, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %327 = "llvm.fadd"(%325, %326) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %328 = "nvvm.shfl.sync"(%115, %327, %118, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %329 = "llvm.fadd"(%327, %328) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %330 = "nvvm.shfl.sync"(%115, %329, %110, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %331 = "llvm.fadd"(%329, %330) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %332 = "nvvm.shfl.sync"(%115, %331, %123, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %333 = "llvm.fadd"(%331, %332) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %334 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %335 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %336 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %337 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %338 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %339 = "llvm.mul"(%335, %337) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %340 = "llvm.add"(%130, %339) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %341 = "llvm.mul"(%336, %337) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %342 = "llvm.mul"(%341, %338) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %343 = "llvm.add"(%340, %342) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %344 = "llvm.sdiv"(%343, %119) : (i32, i32) -> i32
      %345 = "llvm.mul"(%344, %119) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %346 = "llvm.icmp"(%343, %345) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %347 = "llvm.icmp"(%343, %112) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %348 = "llvm.icmp"(%347, %108) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %349 = "llvm.and"(%346, %348) : (i1, i1) -> i1
      %350 = "llvm.add"(%344, %115) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %351 = "llvm.select"(%349, %350, %344) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %352 = "llvm.sdiv"(%351, %110) : (i32, i32) -> i32
      %353 = "llvm.mul"(%352, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %354 = "llvm.icmp"(%351, %353) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %355 = "llvm.icmp"(%351, %112) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %356 = "llvm.icmp"(%355, %108) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %357 = "llvm.and"(%354, %356) : (i1, i1) -> i1
      %358 = "llvm.add"(%352, %115) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %359 = "llvm.select"(%357, %358, %352) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %360 = "llvm.srem"(%351, %110) : (i32, i32) -> i32
      %361 = "llvm.icmp"(%334, %112) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%361)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %362 = "llvm.mul"(%360, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %363 = "llvm.add"(%359, %362) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %364 = "llvm.getelementptr"(%134, %363) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %365 = "llvm.ptrtoint"(%364) : (!llvm.ptr<3>) -> i64
      %366 = "llvm.inttoptr"(%365) : (i64) -> !llvm.ptr<3>
      "llvm.store"(%333, %366) <{alignment = 4 : i64, ordering = 0 : i64}> : (f32, !llvm.ptr<3>) -> ()
      "llvm.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      "llvm.inline_asm"(%112) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %367 = "llvm.icmp"(%334, %110) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%367)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %368 = "llvm.mul"(%334, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %369 = "llvm.add"(%359, %368) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %370 = "llvm.getelementptr"(%134, %369) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %371 = "llvm.ptrtoint"(%370) : (!llvm.ptr<3>) -> i64
      %372 = "llvm.inttoptr"(%371) : (i64) -> !llvm.ptr<3>
      %373 = "llvm.load"(%372) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> f32
      "llvm.br"(%373)[^bb26] : (f32) -> ()
    ^bb25:  // pred: ^bb23
      "llvm.br"(%114)[^bb26] : (f32) -> ()
    ^bb26(%374: f32):  // 2 preds: ^bb24, ^bb25
      "llvm.br"()[^bb27] : () -> ()
    ^bb27:  // pred: ^bb26
      %375 = "nvvm.shfl.sync"(%115, %374, %116, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %376 = "llvm.fadd"(%374, %375) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %377 = "nvvm.shfl.sync"(%115, %376, %122, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %378 = "llvm.fadd"(%376, %377) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %379 = "nvvm.shfl.sync"(%115, %378, %118, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %380 = "llvm.fadd"(%378, %379) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %381 = "nvvm.shfl.sync"(%115, %380, %110, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %382 = "llvm.fadd"(%380, %381) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %383 = "nvvm.shfl.sync"(%115, %382, %123, %117) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %384 = "llvm.fadd"(%382, %383) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %385 = "llvm.fdiv"(%384, %120) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %386 = "llvm.fadd"(%385, %arg15) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %387 = "math.rsqrt"(%386) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%112) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "llvm.br"(%112)[^bb28] : (i32) -> ()
    ^bb28(%388: i32):  // 2 preds: ^bb27, ^bb29
      %389 = "llvm.icmp"(%388, %122) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%389)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb29:  // pred: ^bb28
      %390 = "llvm.mul"(%388, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %391 = "llvm.getelementptr"(%148, %390) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %392 = "llvm.mul"(%388, %122) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %393 = "llvm.getelementptr"(%128, %392) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %394 = "llvm.load"(%391) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%394, %393) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %395 = "llvm.add"(%388, %123) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%395)[^bb28] : (i32) -> ()
    ^bb30:  // pred: ^bb28
      %396 = "llvm.load"(%128) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %397 = "llvm.fpext"(%396) : (vector<64xbf16>) -> vector<64xf32>
      %398 = "vector.broadcast"(%387) : (f32) -> vector<64xf32>
      %399 = "llvm.fmul"(%397, %398) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %400 = "llvm.load"(%126) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %401 = "llvm.fpext"(%400) : (vector<64xbf16>) -> vector<64xf32>
      %402 = "llvm.fmul"(%399, %401) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %403 = "llvm.fptrunc"(%402) : (vector<64xf32>) -> vector<64xbf16>
      "llvm.store"(%403, %127) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xbf16>, !llvm.ptr) -> ()
      "llvm.cond_br"(%198)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %404 = "llvm.load"(%125) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %405 = "llvm.icmp"(%404, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%405)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %406 = "llvm.load"(%127) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%406, %149) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %407 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %408 = "llvm.load"(%407) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %409 = "llvm.icmp"(%408, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%409)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %410 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %411 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %412 = "llvm.load"(%410) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%412, %411) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %413 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %414 = "llvm.load"(%413) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %415 = "llvm.icmp"(%414, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%415)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %416 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %417 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %418 = "llvm.load"(%416) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%418, %417) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %419 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %420 = "llvm.load"(%419) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %421 = "llvm.icmp"(%420, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%421)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %422 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %423 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %424 = "llvm.load"(%422) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%424, %423) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %425 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %426 = "llvm.load"(%425) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %427 = "llvm.icmp"(%426, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%427)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %428 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %429 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %430 = "llvm.load"(%428) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%430, %429) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %431 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %432 = "llvm.load"(%431) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %433 = "llvm.icmp"(%432, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%433)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %434 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %435 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %436 = "llvm.load"(%434) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%436, %435) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %437 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %438 = "llvm.load"(%437) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %439 = "llvm.icmp"(%438, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%439)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %440 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %441 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %442 = "llvm.load"(%440) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%442, %441) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %443 = "llvm.getelementptr"(%125) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %444 = "llvm.load"(%443) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %445 = "llvm.icmp"(%444, %113) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%445)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %446 = "llvm.getelementptr"(%127) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %447 = "llvm.getelementptr"(%149) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %448 = "llvm.load"(%446) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%448, %447) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb47] : () -> ()
    ^bb47:  // 2 preds: ^bb45, ^bb46
      "llvm.br"()[^bb48] : () -> ()
    ^bb48:  // 2 preds: ^bb30, ^bb47
      "llvm.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {}, {}, {}], function_type = !llvm.func<i32 (ptr<1>, ptr<1>, ptr<1>, i32, f32, ptr)>, linkage = #llvm.linkage<external>, sym_name = "cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0", visibility_ = 0 : i64}> ({
  ^bb0(%arg6: !llvm.ptr<1>, %arg7: !llvm.ptr<1>, %arg8: !llvm.ptr<1>, %arg9: i32, %arg10: f32, %arg11: !llvm.ptr):
    %1 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
    %2 = "llvm.mlir.addressof"() <{global_name = @"%s\0A"}> : () -> !llvm.ptr
    %3 = "llvm.mlir.addressof"() <{global_name = @"ERROR: Reached max number of attributes, unable to add more attributes."}> : () -> !llvm.ptr
    %4 = "llvm.mlir.constant"() <{value = 6 : i32}> : () -> i32
    %5 = "llvm.mlir.constant"() <{value = false}> : () -> i1
    %6 = "llvm.mlir.constant"() <{value = true}> : () -> i1
    %7 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
    %8 = "llvm.mlir.undef"() : () -> !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>
    %9 = "llvm.mlir.undef"() : () -> !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %10 = "llvm.mlir.constant"() <{value = 16400 : i64}> : () -> i64
    %11 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %12 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %13 = "llvm.mlir.constant"() <{value = 128 : i32}> : () -> i32
    %14 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %15 = "llvm.mlir.poison"() : () -> !llvm.struct<(struct<()>, struct<()>)>
    %16 = "llvm.mlir.poison"() : () -> !llvm.struct<()>
    %17 = "llvm.mlir.undef"() : () -> !llvm.struct<(i32, struct<()>)>
    %18 = "llvm.insertvalue"(%17, %arg9) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>, i32) -> !llvm.struct<(i32, struct<()>)>
    %19 = "llvm.insertvalue"(%18, %16) <{position = array<i64: 1>}> : (!llvm.struct<(i32, struct<()>)>, !llvm.struct<()>) -> !llvm.struct<(i32, struct<()>)>
    %20 = "llvm.insertvalue"(%9, %arg6) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr<1>) -> !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %21 = "llvm.insertvalue"(%20, %19) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(i32, struct<()>)>) -> !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %22 = "llvm.insertvalue"(%9, %arg8) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.ptr<1>) -> !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %23 = "llvm.insertvalue"(%22, %19) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(i32, struct<()>)>) -> !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %24 = "llvm.insertvalue"(%8, %arg7) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.ptr<1>) -> !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>
    %25 = "llvm.insertvalue"(%24, %15) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(struct<()>, struct<()>)>) -> !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>
    %26 = "llvm.select"(%6, %7, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %27 = "llvm.add"(%26, %arg9) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %28 = "llvm.sdiv"(%27, %14) : (i32, i32) -> i32
    %29 = "llvm.add"(%28, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %30 = "llvm.sub"(%11, %arg9) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %31 = "llvm.sdiv"(%30, %14) : (i32, i32) -> i32
    %32 = "llvm.sub"(%11, %31) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %33 = "llvm.icmp"(%arg9, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %34 = "llvm.icmp"(%arg9, %11) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %35 = "llvm.and"(%33, %5) : (i1, i1) -> i1
    %36 = "llvm.and"(%34, %6) : (i1, i1) -> i1
    %37 = "llvm.or"(%35, %36) : (i1, i1) -> i1
    %38 = "llvm.select"(%37, %29, %32) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %39 = "llvm.alloca"(%12) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>}> : (i32) -> !llvm.ptr
    %40 = "llvm.alloca"(%12) <{elem_type = !llvm.array<3 x struct<(i32, array<4 x i8>, array<64 x i8>)>>}> : (i32) -> !llvm.ptr
    %41 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%40, %41) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %42 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%13, %42) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %43 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%12, %43) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %44 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%12, %44) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %45 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%10, %45) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %46 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%38, %46) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %47 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%12, %47) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %48 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%12, %48) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %49 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %49) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %50 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%arg11, %50) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %51 = "llvm.alloca"(%12) <{elem_type = !llvm.array<1 x ptr>}> : (i32) -> !llvm.ptr
    %52 = "llvm.getelementptr"(%51) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%39, %52) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %53 = "llvm.getelementptr"(%51) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %54 = "llvm.load"(%53) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %55 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %56 = "llvm.load"(%55) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %57 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %58 = "llvm.load"(%57) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%11)[^bb7] : (i32) -> ()
  ^bb1(%59: i32):  // 2 preds: ^bb3, ^bb5
    %60 = "llvm.getelementptr"(%58, %59) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %61 = "llvm.getelementptr"(%60) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%4, %61) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %62 = "llvm.getelementptr"(%60) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %62) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb2:  // pred: ^bb4
    %63 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %64 = "llvm.getelementptr"(%2) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %65 = "llvm.call"(%64, %63) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb3:  // pred: ^bb4
    %66 = "llvm.add"(%56, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%66, %55) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%56)[^bb1] : (i32) -> ()
  ^bb4:  // pred: ^bb7
    %67 = "llvm.icmp"(%56, %1) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%67)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb6
    "llvm.br"(%73)[^bb1] : (i32) -> ()
  ^bb6:  // pred: ^bb7
    %68 = "llvm.getelementptr"(%58, %73) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %69 = "llvm.getelementptr"(%68) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %70 = "llvm.load"(%69) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %71 = "llvm.icmp"(%70, %4) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %72 = "llvm.add"(%73, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%71, %72)[^bb5, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb7(%73: i32):  // 2 preds: ^bb0, ^bb6
    %74 = "llvm.icmp"(%73, %56) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%74)[^bb4, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb8:  // pred: ^bb1
    %75 = "llvm.getelementptr"(%51) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %76 = "llvm.load"(%75) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %77 = "llvm.getelementptr"(%76) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %78 = "llvm.load"(%77) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %79 = "llvm.getelementptr"(%76) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %80 = "llvm.load"(%79) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%11)[^bb15] : (i32) -> ()
  ^bb9(%81: i32):  // 2 preds: ^bb11, ^bb13
    %82 = "llvm.getelementptr"(%80, %81) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %83 = "llvm.getelementptr"(%82) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%14, %83) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %84 = "llvm.getelementptr"(%82) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %84) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb16] : () -> ()
  ^bb10:  // pred: ^bb12
    %85 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %86 = "llvm.getelementptr"(%2) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %87 = "llvm.call"(%86, %85) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb11:  // pred: ^bb12
    %88 = "llvm.add"(%78, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%88, %77) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%78)[^bb9] : (i32) -> ()
  ^bb12:  // pred: ^bb15
    %89 = "llvm.icmp"(%78, %1) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%89)[^bb10, ^bb11] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb14
    "llvm.br"(%95)[^bb9] : (i32) -> ()
  ^bb14:  // pred: ^bb15
    %90 = "llvm.getelementptr"(%80, %95) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %91 = "llvm.getelementptr"(%90) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %92 = "llvm.load"(%91) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %93 = "llvm.icmp"(%92, %14) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %94 = "llvm.add"(%95, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%93, %94)[^bb13, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb15(%95: i32):  // 2 preds: ^bb8, ^bb14
    %96 = "llvm.icmp"(%95, %78) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%96)[^bb12, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb16:  // pred: ^bb9
    %97 = "builtin.unrealized_conversion_cast"(%51) : (!llvm.ptr) -> !cuda.launch_cfg<max_attrs = 3>
    %98 = "cuda.launch_ex"(%97, %21, %25, %23, %arg10) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32) -> !cuda.result
    %99 = "builtin.unrealized_conversion_cast"(%98) : (!cuda.result) -> i32
    "cuda.return_if_error"(%99) : (i32) -> ()
    "llvm.return"(%11) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {}, {}, {}], function_type = !llvm.func<i32 (ptr<1>, ptr<1>, ptr<1>, i32, f32, ptr)>, linkage = #llvm.linkage<external>, sym_name = "_mlir_ciface_cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.ptr<1>, %arg1: !llvm.ptr<1>, %arg2: !llvm.ptr<1>, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr):
    %0 = "llvm.call"(%arg0, %arg1, %arg2, %arg3, %arg4, %arg5) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 6, 0>}> : (!llvm.ptr<1>, !llvm.ptr<1>, !llvm.ptr<1>, i32, f32, !llvm.ptr) -> i32
    "llvm.return"(%0) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
