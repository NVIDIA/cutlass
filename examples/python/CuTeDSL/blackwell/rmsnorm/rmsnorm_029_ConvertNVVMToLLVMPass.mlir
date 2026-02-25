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
      %95 = "llvm.mlir.constant"() <{value = 3584 : i32}> : () -> i32
      %96 = "llvm.mlir.constant"() <{value = 3072 : i32}> : () -> i32
      %97 = "llvm.mlir.constant"() <{value = 2560 : i32}> : () -> i32
      %98 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
      %99 = "llvm.mlir.constant"() <{value = 1536 : i32}> : () -> i32
      %100 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
      %101 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
      %102 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
      %103 = "llvm.mlir.constant"() <{value = false}> : () -> i1
      %104 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
      %105 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
      %106 = "llvm.mlir.constant"() <{value = 4096 : i32}> : () -> i32
      %107 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %108 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %109 = "llvm.mlir.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %110 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
      %111 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      %112 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
      %113 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
      %114 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
      %115 = "llvm.mlir.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %116 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
      %117 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
      %118 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
      %119 = "llvm.alloca"(%117) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %120 = "llvm.alloca"(%117) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %121 = "llvm.alloca"(%116) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %122 = "llvm.alloca"(%116) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %123 = "llvm.alloca"(%116) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %124 = "llvm.extractvalue"(%arg13) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>) -> !llvm.ptr<1>
      %125 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %126 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %127 = "llvm.extractvalue"(%arg12) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.struct<(i32, struct<()>)>
      %128 = "llvm.extractvalue"(%127) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>) -> i32
      %129 = "llvm.getelementptr"(%104) <{elem_type = i8, rawConstantIndices = array<i32: 16384>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %130 = "llvm.mul"(%126, %102) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %131 = "llvm.extractvalue"(%arg12) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %132 = "llvm.getelementptr"(%131, %130) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %133 = "llvm.extractvalue"(%arg14) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %134 = "llvm.getelementptr"(%133, %130) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %135 = "llvm.mul"(%126, %105) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %136 = "llvm.sdiv"(%125, %116) : (i32, i32) -> i32
      %137 = "llvm.srem"(%125, %116) : (i32, i32) -> i32
      %138 = "llvm.mul"(%137, %117) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %139 = "llvm.mul"(%136, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %140 = "llvm.add"(%138, %139) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %141 = "llvm.getelementptr"(%132, %140) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %142 = "llvm.getelementptr"(%104, %140) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %143 = "llvm.getelementptr"(%134, %140) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %144 = "llvm.add"(%135, %136) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %145 = "llvm.getelementptr"(%124, %138) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %146 = "llvm.icmp"(%138, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %147 = "llvm.zext"(%146) : (i1) -> i8
      %148 = "llvm.ptrtoint"(%120) : (!llvm.ptr) -> i64
      %149 = "llvm.inttoptr"(%148) : (i64) -> !llvm.ptr
      "llvm.store"(%147, %149) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %150 = "llvm.add"(%138, %101) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %151 = "llvm.icmp"(%150, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %152 = "llvm.zext"(%151) : (i1) -> i8
      %153 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %154 = "llvm.ptrtoint"(%153) : (!llvm.ptr) -> i64
      %155 = "llvm.inttoptr"(%154) : (i64) -> !llvm.ptr
      "llvm.store"(%152, %155) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %156 = "llvm.add"(%138, %100) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %157 = "llvm.icmp"(%156, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %158 = "llvm.zext"(%157) : (i1) -> i8
      %159 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %160 = "llvm.ptrtoint"(%159) : (!llvm.ptr) -> i64
      %161 = "llvm.inttoptr"(%160) : (i64) -> !llvm.ptr
      "llvm.store"(%158, %161) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %162 = "llvm.add"(%138, %99) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %163 = "llvm.icmp"(%162, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %164 = "llvm.zext"(%163) : (i1) -> i8
      %165 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %166 = "llvm.ptrtoint"(%165) : (!llvm.ptr) -> i64
      %167 = "llvm.inttoptr"(%166) : (i64) -> !llvm.ptr
      "llvm.store"(%164, %167) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %168 = "llvm.add"(%138, %98) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %169 = "llvm.icmp"(%168, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %170 = "llvm.zext"(%169) : (i1) -> i8
      %171 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %172 = "llvm.ptrtoint"(%171) : (!llvm.ptr) -> i64
      %173 = "llvm.inttoptr"(%172) : (i64) -> !llvm.ptr
      "llvm.store"(%170, %173) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %174 = "llvm.add"(%138, %97) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %175 = "llvm.icmp"(%174, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %176 = "llvm.zext"(%175) : (i1) -> i8
      %177 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %178 = "llvm.ptrtoint"(%177) : (!llvm.ptr) -> i64
      %179 = "llvm.inttoptr"(%178) : (i64) -> !llvm.ptr
      "llvm.store"(%176, %179) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %180 = "llvm.add"(%138, %96) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %181 = "llvm.icmp"(%180, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %182 = "llvm.zext"(%181) : (i1) -> i8
      %183 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %184 = "llvm.ptrtoint"(%183) : (!llvm.ptr) -> i64
      %185 = "llvm.inttoptr"(%184) : (i64) -> !llvm.ptr
      "llvm.store"(%182, %185) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %186 = "llvm.add"(%138, %95) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %187 = "llvm.icmp"(%186, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %188 = "llvm.zext"(%187) : (i1) -> i8
      %189 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %190 = "llvm.ptrtoint"(%189) : (!llvm.ptr) -> i64
      %191 = "llvm.inttoptr"(%190) : (i64) -> !llvm.ptr
      "llvm.store"(%188, %191) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %192 = "llvm.icmp"(%144, %128) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%192)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %193 = "llvm.load"(%120) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %194 = "llvm.trunc"(%193) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %195 = "llvm.select"(%194, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %196 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%142, %141, %196, %195) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %197 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %198 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %199 = "llvm.load"(%153) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %200 = "llvm.trunc"(%199) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %201 = "llvm.select"(%200, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %202 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%198, %197, %202, %201) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %203 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %204 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %205 = "llvm.load"(%159) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %206 = "llvm.trunc"(%205) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %207 = "llvm.select"(%206, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %208 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%204, %203, %208, %207) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %209 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %210 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %211 = "llvm.load"(%165) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %212 = "llvm.trunc"(%211) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %213 = "llvm.select"(%212, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %214 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%210, %209, %214, %213) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %215 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %216 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %217 = "llvm.load"(%171) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %218 = "llvm.trunc"(%217) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %219 = "llvm.select"(%218, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %220 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%216, %215, %220, %219) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %221 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %222 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %223 = "llvm.load"(%177) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %224 = "llvm.trunc"(%223) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %225 = "llvm.select"(%224, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %226 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%222, %221, %226, %225) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %227 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %228 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %229 = "llvm.load"(%183) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %230 = "llvm.trunc"(%229) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %231 = "llvm.select"(%230, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %232 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%228, %227, %232, %231) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %233 = "llvm.getelementptr"(%141) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %234 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %235 = "llvm.load"(%189) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %236 = "llvm.trunc"(%235) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %237 = "llvm.select"(%236, %111, %107) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %238 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      "llvm.inline_asm"(%234, %233, %238, %237) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      "llvm.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "nvvm.cp.async.commit.group"() : () -> ()
      %239 = "llvm.ptrtoint"(%119) : (!llvm.ptr) -> i64
      %240 = "llvm.inttoptr"(%239) : (i64) -> !llvm.ptr
      "llvm.store"(%147, %240) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %241 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %242 = "llvm.ptrtoint"(%241) : (!llvm.ptr) -> i64
      %243 = "llvm.inttoptr"(%242) : (i64) -> !llvm.ptr
      "llvm.store"(%152, %243) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %244 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %245 = "llvm.ptrtoint"(%244) : (!llvm.ptr) -> i64
      %246 = "llvm.inttoptr"(%245) : (i64) -> !llvm.ptr
      "llvm.store"(%158, %246) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %247 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %248 = "llvm.ptrtoint"(%247) : (!llvm.ptr) -> i64
      %249 = "llvm.inttoptr"(%248) : (i64) -> !llvm.ptr
      "llvm.store"(%164, %249) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %250 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %251 = "llvm.ptrtoint"(%250) : (!llvm.ptr) -> i64
      %252 = "llvm.inttoptr"(%251) : (i64) -> !llvm.ptr
      "llvm.store"(%170, %252) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %253 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %254 = "llvm.ptrtoint"(%253) : (!llvm.ptr) -> i64
      %255 = "llvm.inttoptr"(%254) : (i64) -> !llvm.ptr
      "llvm.store"(%176, %255) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %256 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %257 = "llvm.ptrtoint"(%256) : (!llvm.ptr) -> i64
      %258 = "llvm.inttoptr"(%257) : (i64) -> !llvm.ptr
      "llvm.store"(%182, %258) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %259 = "llvm.getelementptr"(%119) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %260 = "llvm.ptrtoint"(%259) : (!llvm.ptr) -> i64
      %261 = "llvm.inttoptr"(%260) : (i64) -> !llvm.ptr
      "llvm.store"(%188, %261) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %262 = "llvm.load"(%119) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %263 = "llvm.icmp"(%262, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%263)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      %264 = "llvm.load"(%145) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%264, %121) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %265 = "llvm.load"(%241) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %266 = "llvm.icmp"(%265, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%266)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %267 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %268 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %269 = "llvm.load"(%267) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%269, %268) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %270 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %271 = "llvm.icmp"(%270, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%271)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %272 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %273 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %274 = "llvm.load"(%272) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%274, %273) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %275 = "llvm.load"(%247) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %276 = "llvm.icmp"(%275, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%276)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %277 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %278 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %279 = "llvm.load"(%277) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%279, %278) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %280 = "llvm.load"(%250) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %281 = "llvm.icmp"(%280, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%281)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %282 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %283 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %284 = "llvm.load"(%282) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%284, %283) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %285 = "llvm.load"(%253) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %286 = "llvm.icmp"(%285, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%286)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %287 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %288 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %289 = "llvm.load"(%287) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%289, %288) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb14] : () -> ()
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %290 = "llvm.load"(%256) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %291 = "llvm.icmp"(%290, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%291)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %292 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %293 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %294 = "llvm.load"(%292) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%294, %293) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb16] : () -> ()
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %295 = "llvm.load"(%259) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %296 = "llvm.icmp"(%295, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%296)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %297 = "llvm.getelementptr"(%145) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %298 = "llvm.getelementptr"(%121) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %299 = "llvm.load"(%297) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%299, %298) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb18] : () -> ()
    ^bb18:  // 2 preds: ^bb16, ^bb17
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      "llvm.br"(%107)[^bb19] : (i32) -> ()
    ^bb19(%300: i32):  // 2 preds: ^bb18, ^bb20
      %301 = "llvm.icmp"(%300, %117) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%301)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %302 = "llvm.mul"(%300, %101) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %303 = "llvm.getelementptr"(%142, %302) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %304 = "llvm.mul"(%300, %117) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %305 = "llvm.getelementptr"(%123, %304) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %306 = "llvm.load"(%303) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%306, %305) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %307 = "llvm.add"(%300, %118) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%307)[^bb19] : (i32) -> ()
    ^bb21:  // pred: ^bb19
      %308 = "llvm.load"(%123) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %309 = "llvm.fpext"(%308) : (vector<64xbf16>) -> vector<64xf32>
      %310 = "llvm.fmul"(%309, %309) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %311 = "llvm.intr.vector.reduce.fadd"(%109, %310) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
      %312 = "nvvm.shfl.sync"(%110, %311, %111, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %313 = "llvm.fadd"(%312, %311) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %314 = "nvvm.shfl.sync"(%110, %313, %117, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %315 = "llvm.fadd"(%313, %314) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %316 = "nvvm.shfl.sync"(%110, %315, %113, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %317 = "llvm.fadd"(%315, %316) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %318 = "nvvm.shfl.sync"(%110, %317, %105, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %319 = "llvm.fadd"(%317, %318) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %320 = "nvvm.shfl.sync"(%110, %319, %118, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %321 = "llvm.fadd"(%319, %320) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %322 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %323 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %324 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %325 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %326 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %327 = "llvm.mul"(%323, %325) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %328 = "llvm.add"(%125, %327) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %329 = "llvm.mul"(%324, %325) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %330 = "llvm.mul"(%329, %326) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %331 = "llvm.add"(%328, %330) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %332 = "llvm.sdiv"(%331, %114) : (i32, i32) -> i32
      %333 = "llvm.mul"(%332, %114) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %334 = "llvm.icmp"(%331, %333) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %335 = "llvm.icmp"(%331, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %336 = "llvm.icmp"(%335, %103) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %337 = "llvm.and"(%334, %336) : (i1, i1) -> i1
      %338 = "llvm.add"(%332, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %339 = "llvm.select"(%337, %338, %332) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %340 = "llvm.sdiv"(%339, %105) : (i32, i32) -> i32
      %341 = "llvm.mul"(%340, %105) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %342 = "llvm.icmp"(%339, %341) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %343 = "llvm.icmp"(%339, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %344 = "llvm.icmp"(%343, %103) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %345 = "llvm.and"(%342, %344) : (i1, i1) -> i1
      %346 = "llvm.add"(%340, %110) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %347 = "llvm.select"(%345, %346, %340) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %348 = "llvm.srem"(%339, %105) : (i32, i32) -> i32
      %349 = "llvm.icmp"(%322, %107) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%349)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %350 = "llvm.mul"(%348, %105) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %351 = "llvm.add"(%347, %350) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %352 = "llvm.getelementptr"(%129, %351) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %353 = "llvm.ptrtoint"(%352) : (!llvm.ptr<3>) -> i64
      %354 = "llvm.inttoptr"(%353) : (i64) -> !llvm.ptr<3>
      "llvm.store"(%321, %354) <{alignment = 4 : i64, ordering = 0 : i64}> : (f32, !llvm.ptr<3>) -> ()
      "llvm.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      "llvm.inline_asm"(%107) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %355 = "llvm.icmp"(%322, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%355)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %356 = "llvm.mul"(%322, %105) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %357 = "llvm.add"(%347, %356) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %358 = "llvm.getelementptr"(%129, %357) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %359 = "llvm.ptrtoint"(%358) : (!llvm.ptr<3>) -> i64
      %360 = "llvm.inttoptr"(%359) : (i64) -> !llvm.ptr<3>
      %361 = "llvm.load"(%360) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> f32
      "llvm.br"(%361)[^bb26] : (f32) -> ()
    ^bb25:  // pred: ^bb23
      "llvm.br"(%109)[^bb26] : (f32) -> ()
    ^bb26(%362: f32):  // 2 preds: ^bb24, ^bb25
      "llvm.br"()[^bb27] : () -> ()
    ^bb27:  // pred: ^bb26
      %363 = "nvvm.shfl.sync"(%110, %362, %111, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %364 = "llvm.fadd"(%362, %363) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %365 = "nvvm.shfl.sync"(%110, %364, %117, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %366 = "llvm.fadd"(%364, %365) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %367 = "nvvm.shfl.sync"(%110, %366, %113, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %368 = "llvm.fadd"(%366, %367) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %369 = "nvvm.shfl.sync"(%110, %368, %105, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %370 = "llvm.fadd"(%368, %369) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %371 = "nvvm.shfl.sync"(%110, %370, %118, %112) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %372 = "llvm.fadd"(%370, %371) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %373 = "llvm.fdiv"(%372, %115) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %374 = "llvm.fadd"(%373, %arg15) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %375 = "math.rsqrt"(%374) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%107) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "llvm.br"(%107)[^bb28] : (i32) -> ()
    ^bb28(%376: i32):  // 2 preds: ^bb27, ^bb29
      %377 = "llvm.icmp"(%376, %117) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%377)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb29:  // pred: ^bb28
      %378 = "llvm.mul"(%376, %101) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %379 = "llvm.getelementptr"(%142, %378) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %380 = "llvm.mul"(%376, %117) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %381 = "llvm.getelementptr"(%123, %380) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %382 = "llvm.load"(%379) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%382, %381) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %383 = "llvm.add"(%376, %118) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%383)[^bb28] : (i32) -> ()
    ^bb30:  // pred: ^bb28
      %384 = "llvm.load"(%123) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %385 = "llvm.fpext"(%384) : (vector<64xbf16>) -> vector<64xf32>
      %386 = "llvm.mlir.undef"() : () -> vector<64xf32>
      %387 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %388 = "llvm.insertelement"(%386, %375, %387) : (vector<64xf32>, f32, i32) -> vector<64xf32>
      %389 = "llvm.shufflevector"(%388, %386) <{mask = array<i32: 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %390 = "llvm.fmul"(%385, %389) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %391 = "llvm.load"(%121) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %392 = "llvm.fpext"(%391) : (vector<64xbf16>) -> vector<64xf32>
      %393 = "llvm.fmul"(%390, %392) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %394 = "llvm.fptrunc"(%393) : (vector<64xf32>) -> vector<64xbf16>
      "llvm.store"(%394, %122) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xbf16>, !llvm.ptr) -> ()
      "llvm.cond_br"(%192)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %395 = "llvm.load"(%120) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %396 = "llvm.icmp"(%395, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%396)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %397 = "llvm.load"(%122) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%397, %143) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %398 = "llvm.load"(%153) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %399 = "llvm.icmp"(%398, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%399)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %400 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %401 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %402 = "llvm.load"(%400) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%402, %401) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %403 = "llvm.load"(%159) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %404 = "llvm.icmp"(%403, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%404)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %405 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %406 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %407 = "llvm.load"(%405) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%407, %406) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %408 = "llvm.load"(%165) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %409 = "llvm.icmp"(%408, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%409)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %410 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %411 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %412 = "llvm.load"(%410) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%412, %411) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %413 = "llvm.load"(%171) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %414 = "llvm.icmp"(%413, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%414)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %415 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %416 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %417 = "llvm.load"(%415) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%417, %416) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %418 = "llvm.load"(%177) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %419 = "llvm.icmp"(%418, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%419)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %420 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %421 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %422 = "llvm.load"(%420) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%422, %421) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %423 = "llvm.load"(%183) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %424 = "llvm.icmp"(%423, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%424)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %425 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %426 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %427 = "llvm.load"(%425) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%427, %426) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %428 = "llvm.load"(%189) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %429 = "llvm.icmp"(%428, %108) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%429)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %430 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %431 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %432 = "llvm.load"(%430) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%432, %431) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
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
    %53 = "llvm.load"(%52) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %54 = "llvm.getelementptr"(%53) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %55 = "llvm.load"(%54) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %56 = "llvm.getelementptr"(%53) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %57 = "llvm.load"(%56) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%11)[^bb7] : (i32) -> ()
  ^bb1(%58: i32):  // 2 preds: ^bb3, ^bb5
    %59 = "llvm.getelementptr"(%57, %58) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %60 = "llvm.getelementptr"(%59) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%4, %60) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %61 = "llvm.getelementptr"(%59) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %61) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb2:  // 2 preds: ^bb4, ^bb11
    %62 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %63 = "llvm.getelementptr"(%2) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %64 = "llvm.call"(%63, %62) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb3:  // pred: ^bb4
    %65 = "llvm.add"(%55, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%65, %54) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%55)[^bb1] : (i32) -> ()
  ^bb4:  // pred: ^bb7
    %66 = "llvm.icmp"(%55, %1) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%66)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb6
    "llvm.br"(%72)[^bb1] : (i32) -> ()
  ^bb6:  // pred: ^bb7
    %67 = "llvm.getelementptr"(%57, %72) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %68 = "llvm.getelementptr"(%67) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %69 = "llvm.load"(%68) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %70 = "llvm.icmp"(%69, %4) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %71 = "llvm.add"(%72, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%70, %71)[^bb5, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb7(%72: i32):  // 2 preds: ^bb0, ^bb6
    %73 = "llvm.icmp"(%72, %55) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%73)[^bb4, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb8:  // pred: ^bb1
    %74 = "llvm.load"(%52) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %75 = "llvm.getelementptr"(%74) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %76 = "llvm.load"(%75) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %77 = "llvm.getelementptr"(%74) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %78 = "llvm.load"(%77) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%11)[^bb14] : (i32) -> ()
  ^bb9(%79: i32):  // 2 preds: ^bb10, ^bb12
    %80 = "llvm.getelementptr"(%78, %79) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %81 = "llvm.getelementptr"(%80) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%14, %81) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %82 = "llvm.getelementptr"(%80) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %82) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb15] : () -> ()
  ^bb10:  // pred: ^bb11
    %83 = "llvm.add"(%76, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%83, %75) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%76)[^bb9] : (i32) -> ()
  ^bb11:  // pred: ^bb14
    %84 = "llvm.icmp"(%76, %1) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%84)[^bb2, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb12:  // pred: ^bb13
    "llvm.br"(%90)[^bb9] : (i32) -> ()
  ^bb13:  // pred: ^bb14
    %85 = "llvm.getelementptr"(%78, %90) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %86 = "llvm.getelementptr"(%85) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %87 = "llvm.load"(%86) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %88 = "llvm.icmp"(%87, %14) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %89 = "llvm.add"(%90, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%88, %89)[^bb12, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb14(%90: i32):  // 2 preds: ^bb8, ^bb13
    %91 = "llvm.icmp"(%90, %76) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%91)[^bb11, ^bb13] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb15:  // pred: ^bb9
    %92 = "builtin.unrealized_conversion_cast"(%51) : (!llvm.ptr) -> !cuda.launch_cfg<max_attrs = 3>
    %93 = "cuda.launch_ex"(%92, %21, %25, %23, %arg10) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32) -> !cuda.result
    %94 = "builtin.unrealized_conversion_cast"(%93) : (!cuda.result) -> i32
    "cuda.return_if_error"(%94) : (i32) -> ()
    "llvm.return"(%11) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {llvm.align = 16 : i64}, {}, {}, {}], function_type = !llvm.func<i32 (ptr<1>, ptr<1>, ptr<1>, i32, f32, ptr)>, linkage = #llvm.linkage<external>, sym_name = "_mlir_ciface_cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.ptr<1>, %arg1: !llvm.ptr<1>, %arg2: !llvm.ptr<1>, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr):
    %0 = "llvm.call"(%arg0, %arg1, %arg2, %arg3, %arg4, %arg5) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 6, 0>}> : (!llvm.ptr<1>, !llvm.ptr<1>, !llvm.ptr<1>, i32, f32, !llvm.ptr) -> i32
    "llvm.return"(%0) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
