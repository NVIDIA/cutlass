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
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<f32 (f32)>, linkage = #llvm.linkage<external>, sym_name = "__nv_rsqrtf", visibility_ = 0 : i64}> ({
    }) : () -> ()
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0", visibility_ = 0 : i64}> ({
    ^bb0(%arg12: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg13: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg14: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg15: f32):
      %95 = "llvm.mlir.undef"() : () -> vector<64xf32>
      %96 = "llvm.mlir.constant"() <{value = 3584 : i32}> : () -> i32
      %97 = "llvm.mlir.constant"() <{value = 3072 : i32}> : () -> i32
      %98 = "llvm.mlir.constant"() <{value = 2560 : i32}> : () -> i32
      %99 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
      %100 = "llvm.mlir.constant"() <{value = 1536 : i32}> : () -> i32
      %101 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
      %102 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
      %103 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
      %104 = "llvm.mlir.constant"() <{value = false}> : () -> i1
      %105 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
      %106 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
      %107 = "llvm.mlir.constant"() <{value = 4096 : i32}> : () -> i32
      %108 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %109 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %110 = "llvm.mlir.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %111 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
      %112 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
      %113 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
      %114 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
      %115 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
      %116 = "llvm.mlir.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %117 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
      %118 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
      %119 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
      %120 = "llvm.alloca"(%118) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %121 = "llvm.alloca"(%118) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
      %122 = "llvm.alloca"(%117) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %123 = "llvm.alloca"(%117) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %124 = "llvm.alloca"(%117) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
      %125 = "llvm.extractvalue"(%arg13) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>) -> !llvm.ptr<1>
      %126 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %127 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %128 = "llvm.extractvalue"(%arg12) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.struct<(i32, struct<()>)>
      %129 = "llvm.extractvalue"(%128) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>) -> i32
      %130 = "llvm.getelementptr"(%105) <{elem_type = i8, rawConstantIndices = array<i32: 16384>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %131 = "llvm.mul"(%127, %103) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %132 = "llvm.extractvalue"(%arg12) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %133 = "llvm.getelementptr"(%132, %131) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %134 = "llvm.extractvalue"(%arg14) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %135 = "llvm.getelementptr"(%134, %131) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %136 = "llvm.mul"(%127, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %137 = "llvm.sdiv"(%126, %117) : (i32, i32) -> i32
      %138 = "llvm.srem"(%126, %117) : (i32, i32) -> i32
      %139 = "llvm.mul"(%138, %118) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %140 = "llvm.mul"(%137, %107) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %141 = "llvm.add"(%139, %140) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %142 = "llvm.getelementptr"(%133, %141) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %143 = "llvm.getelementptr"(%105, %141) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %144 = "llvm.getelementptr"(%135, %141) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %145 = "llvm.add"(%136, %137) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %146 = "llvm.getelementptr"(%125, %139) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %147 = "llvm.icmp"(%139, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %148 = "llvm.zext"(%147) : (i1) -> i8
      %149 = "llvm.ptrtoint"(%121) : (!llvm.ptr) -> i64
      %150 = "llvm.inttoptr"(%149) : (i64) -> !llvm.ptr
      "llvm.store"(%148, %150) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %151 = "llvm.add"(%139, %102) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %152 = "llvm.icmp"(%151, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %153 = "llvm.zext"(%152) : (i1) -> i8
      %154 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %155 = "llvm.ptrtoint"(%154) : (!llvm.ptr) -> i64
      %156 = "llvm.inttoptr"(%155) : (i64) -> !llvm.ptr
      "llvm.store"(%153, %156) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %157 = "llvm.add"(%139, %101) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %158 = "llvm.icmp"(%157, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %159 = "llvm.zext"(%158) : (i1) -> i8
      %160 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %161 = "llvm.ptrtoint"(%160) : (!llvm.ptr) -> i64
      %162 = "llvm.inttoptr"(%161) : (i64) -> !llvm.ptr
      "llvm.store"(%159, %162) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %163 = "llvm.add"(%139, %100) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %164 = "llvm.icmp"(%163, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %165 = "llvm.zext"(%164) : (i1) -> i8
      %166 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %167 = "llvm.ptrtoint"(%166) : (!llvm.ptr) -> i64
      %168 = "llvm.inttoptr"(%167) : (i64) -> !llvm.ptr
      "llvm.store"(%165, %168) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %169 = "llvm.add"(%139, %99) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %170 = "llvm.icmp"(%169, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %171 = "llvm.zext"(%170) : (i1) -> i8
      %172 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %173 = "llvm.ptrtoint"(%172) : (!llvm.ptr) -> i64
      %174 = "llvm.inttoptr"(%173) : (i64) -> !llvm.ptr
      "llvm.store"(%171, %174) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %175 = "llvm.add"(%139, %98) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %176 = "llvm.icmp"(%175, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %177 = "llvm.zext"(%176) : (i1) -> i8
      %178 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %179 = "llvm.ptrtoint"(%178) : (!llvm.ptr) -> i64
      %180 = "llvm.inttoptr"(%179) : (i64) -> !llvm.ptr
      "llvm.store"(%177, %180) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %181 = "llvm.add"(%139, %97) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %182 = "llvm.icmp"(%181, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %183 = "llvm.zext"(%182) : (i1) -> i8
      %184 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %185 = "llvm.ptrtoint"(%184) : (!llvm.ptr) -> i64
      %186 = "llvm.inttoptr"(%185) : (i64) -> !llvm.ptr
      "llvm.store"(%183, %186) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %187 = "llvm.add"(%139, %96) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %188 = "llvm.icmp"(%187, %107) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %189 = "llvm.zext"(%188) : (i1) -> i8
      %190 = "llvm.getelementptr"(%121) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %191 = "llvm.ptrtoint"(%190) : (!llvm.ptr) -> i64
      %192 = "llvm.inttoptr"(%191) : (i64) -> !llvm.ptr
      "llvm.store"(%189, %192) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %193 = "llvm.icmp"(%145, %129) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%193)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %194 = "llvm.load"(%121) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %195 = "llvm.trunc"(%194) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %196 = "llvm.select"(%195, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%143, %142, %112, %196) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %197 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %198 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %199 = "llvm.load"(%154) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %200 = "llvm.trunc"(%199) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %201 = "llvm.select"(%200, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%198, %197, %112, %201) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %202 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %203 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %204 = "llvm.load"(%160) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %205 = "llvm.trunc"(%204) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %206 = "llvm.select"(%205, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%203, %202, %112, %206) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %207 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %208 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %209 = "llvm.load"(%166) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %210 = "llvm.trunc"(%209) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %211 = "llvm.select"(%210, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%208, %207, %112, %211) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %212 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %213 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %214 = "llvm.load"(%172) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %215 = "llvm.trunc"(%214) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %216 = "llvm.select"(%215, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%213, %212, %112, %216) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %217 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %218 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %219 = "llvm.load"(%178) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %220 = "llvm.trunc"(%219) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %221 = "llvm.select"(%220, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%218, %217, %112, %221) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %222 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %223 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %224 = "llvm.load"(%184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %225 = "llvm.trunc"(%224) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %226 = "llvm.select"(%225, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%223, %222, %112, %226) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      %227 = "llvm.getelementptr"(%142) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %228 = "llvm.getelementptr"(%143) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
      %229 = "llvm.load"(%190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %230 = "llvm.trunc"(%229) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %231 = "llvm.select"(%230, %112, %108) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      "llvm.inline_asm"(%228, %227, %112, %231) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
      "llvm.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "nvvm.cp.async.commit.group"() : () -> ()
      %232 = "llvm.ptrtoint"(%120) : (!llvm.ptr) -> i64
      %233 = "llvm.inttoptr"(%232) : (i64) -> !llvm.ptr
      "llvm.store"(%148, %233) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %234 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
      %235 = "llvm.ptrtoint"(%234) : (!llvm.ptr) -> i64
      %236 = "llvm.inttoptr"(%235) : (i64) -> !llvm.ptr
      "llvm.store"(%153, %236) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %237 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
      %238 = "llvm.ptrtoint"(%237) : (!llvm.ptr) -> i64
      %239 = "llvm.inttoptr"(%238) : (i64) -> !llvm.ptr
      "llvm.store"(%159, %239) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %240 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
      %241 = "llvm.ptrtoint"(%240) : (!llvm.ptr) -> i64
      %242 = "llvm.inttoptr"(%241) : (i64) -> !llvm.ptr
      "llvm.store"(%165, %242) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %243 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
      %244 = "llvm.ptrtoint"(%243) : (!llvm.ptr) -> i64
      %245 = "llvm.inttoptr"(%244) : (i64) -> !llvm.ptr
      "llvm.store"(%171, %245) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %246 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
      %247 = "llvm.ptrtoint"(%246) : (!llvm.ptr) -> i64
      %248 = "llvm.inttoptr"(%247) : (i64) -> !llvm.ptr
      "llvm.store"(%177, %248) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %249 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
      %250 = "llvm.ptrtoint"(%249) : (!llvm.ptr) -> i64
      %251 = "llvm.inttoptr"(%250) : (i64) -> !llvm.ptr
      "llvm.store"(%183, %251) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %252 = "llvm.getelementptr"(%120) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
      %253 = "llvm.ptrtoint"(%252) : (!llvm.ptr) -> i64
      %254 = "llvm.inttoptr"(%253) : (i64) -> !llvm.ptr
      "llvm.store"(%189, %254) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
      %255 = "llvm.load"(%120) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %256 = "llvm.icmp"(%255, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%256)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      %257 = "llvm.load"(%146) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%257, %122) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %258 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %259 = "llvm.icmp"(%258, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%259)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %260 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %261 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %262 = "llvm.load"(%260) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%262, %261) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %263 = "llvm.load"(%237) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %264 = "llvm.icmp"(%263, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%264)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %265 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %266 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %267 = "llvm.load"(%265) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%267, %266) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %268 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %269 = "llvm.icmp"(%268, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%269)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %270 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %271 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %272 = "llvm.load"(%270) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%272, %271) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %273 = "llvm.load"(%243) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %274 = "llvm.icmp"(%273, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%274)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %275 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %276 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %277 = "llvm.load"(%275) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%277, %276) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %278 = "llvm.load"(%246) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %279 = "llvm.icmp"(%278, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%279)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %280 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %281 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %282 = "llvm.load"(%280) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%282, %281) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb14] : () -> ()
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %283 = "llvm.load"(%249) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %284 = "llvm.icmp"(%283, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%284)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %285 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %286 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %287 = "llvm.load"(%285) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%287, %286) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb16] : () -> ()
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %288 = "llvm.load"(%252) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %289 = "llvm.icmp"(%288, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%289)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %290 = "llvm.getelementptr"(%146) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %291 = "llvm.getelementptr"(%122) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %292 = "llvm.load"(%290) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%292, %291) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "llvm.br"()[^bb18] : () -> ()
    ^bb18:  // 2 preds: ^bb16, ^bb17
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      "llvm.br"(%108)[^bb19] : (i32) -> ()
    ^bb19(%293: i32):  // 2 preds: ^bb18, ^bb20
      %294 = "llvm.icmp"(%293, %118) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%294)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %295 = "llvm.mul"(%293, %102) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %296 = "llvm.getelementptr"(%143, %295) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %297 = "llvm.mul"(%293, %118) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %298 = "llvm.getelementptr"(%124, %297) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %299 = "llvm.load"(%296) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%299, %298) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %300 = "llvm.add"(%293, %119) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%300)[^bb19] : (i32) -> ()
    ^bb21:  // pred: ^bb19
      %301 = "llvm.load"(%124) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %302 = "llvm.fpext"(%301) : (vector<64xbf16>) -> vector<64xf32>
      %303 = "llvm.fmul"(%302, %302) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %304 = "llvm.intr.vector.reduce.fadd"(%110, %303) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
      %305 = "nvvm.shfl.sync"(%111, %304, %112, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %306 = "llvm.fadd"(%305, %304) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %307 = "nvvm.shfl.sync"(%111, %306, %118, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %308 = "llvm.fadd"(%306, %307) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %309 = "nvvm.shfl.sync"(%111, %308, %114, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %310 = "llvm.fadd"(%308, %309) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %311 = "nvvm.shfl.sync"(%111, %310, %106, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %312 = "llvm.fadd"(%310, %311) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %313 = "nvvm.shfl.sync"(%111, %312, %119, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %314 = "llvm.fadd"(%312, %313) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %315 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %316 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %317 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %318 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %319 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %320 = "llvm.mul"(%316, %318) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %321 = "llvm.add"(%126, %320) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %322 = "llvm.mul"(%317, %318) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %323 = "llvm.mul"(%322, %319) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %324 = "llvm.add"(%321, %323) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %325 = "llvm.sdiv"(%324, %115) : (i32, i32) -> i32
      %326 = "llvm.mul"(%325, %115) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %327 = "llvm.icmp"(%324, %326) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %328 = "llvm.icmp"(%324, %108) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %329 = "llvm.icmp"(%328, %104) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %330 = "llvm.and"(%327, %329) : (i1, i1) -> i1
      %331 = "llvm.add"(%325, %111) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %332 = "llvm.select"(%330, %331, %325) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %333 = "llvm.sdiv"(%332, %106) : (i32, i32) -> i32
      %334 = "llvm.mul"(%333, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %335 = "llvm.icmp"(%332, %334) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %336 = "llvm.icmp"(%332, %108) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %337 = "llvm.icmp"(%336, %104) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %338 = "llvm.and"(%335, %337) : (i1, i1) -> i1
      %339 = "llvm.add"(%333, %111) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %340 = "llvm.select"(%338, %339, %333) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
      %341 = "llvm.srem"(%332, %106) : (i32, i32) -> i32
      %342 = "llvm.icmp"(%315, %108) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%342)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %343 = "llvm.mul"(%341, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %344 = "llvm.add"(%340, %343) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %345 = "llvm.getelementptr"(%130, %344) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %346 = "llvm.ptrtoint"(%345) : (!llvm.ptr<3>) -> i64
      %347 = "llvm.inttoptr"(%346) : (i64) -> !llvm.ptr<3>
      "llvm.store"(%314, %347) <{alignment = 4 : i64, ordering = 0 : i64}> : (f32, !llvm.ptr<3>) -> ()
      "llvm.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      "llvm.inline_asm"(%108) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %348 = "llvm.icmp"(%315, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%348)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %349 = "llvm.mul"(%315, %106) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %350 = "llvm.add"(%340, %349) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %351 = "llvm.getelementptr"(%130, %350) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %352 = "llvm.ptrtoint"(%351) : (!llvm.ptr<3>) -> i64
      %353 = "llvm.inttoptr"(%352) : (i64) -> !llvm.ptr<3>
      %354 = "llvm.load"(%353) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> f32
      "llvm.br"(%354)[^bb26] : (f32) -> ()
    ^bb25:  // pred: ^bb23
      "llvm.br"(%110)[^bb26] : (f32) -> ()
    ^bb26(%355: f32):  // 2 preds: ^bb24, ^bb25
      "llvm.br"()[^bb27] : () -> ()
    ^bb27:  // pred: ^bb26
      %356 = "nvvm.shfl.sync"(%111, %355, %112, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %357 = "llvm.fadd"(%355, %356) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %358 = "nvvm.shfl.sync"(%111, %357, %118, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %359 = "llvm.fadd"(%357, %358) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %360 = "nvvm.shfl.sync"(%111, %359, %114, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %361 = "llvm.fadd"(%359, %360) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %362 = "nvvm.shfl.sync"(%111, %361, %106, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %363 = "llvm.fadd"(%361, %362) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %364 = "nvvm.shfl.sync"(%111, %363, %119, %113) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %365 = "llvm.fadd"(%363, %364) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %366 = "llvm.fdiv"(%365, %116) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %367 = "llvm.fadd"(%366, %arg15) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
      %368 = "llvm.call"(%367) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @__nv_rsqrtf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 1, 0>}> : (f32) -> f32
      "llvm.inline_asm"(%108) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "llvm.br"(%108)[^bb28] : (i32) -> ()
    ^bb28(%369: i32):  // 2 preds: ^bb27, ^bb29
      %370 = "llvm.icmp"(%369, %118) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%370)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb29:  // pred: ^bb28
      %371 = "llvm.mul"(%369, %102) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %372 = "llvm.getelementptr"(%143, %371) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
      %373 = "llvm.mul"(%369, %118) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      %374 = "llvm.getelementptr"(%124, %373) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
      %375 = "llvm.load"(%372) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%375, %374) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %376 = "llvm.add"(%369, %119) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
      "llvm.br"(%376)[^bb28] : (i32) -> ()
    ^bb30:  // pred: ^bb28
      %377 = "llvm.load"(%124) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %378 = "llvm.fpext"(%377) : (vector<64xbf16>) -> vector<64xf32>
      %379 = "llvm.insertelement"(%95, %368, %108) : (vector<64xf32>, f32, i32) -> vector<64xf32>
      %380 = "llvm.shufflevector"(%379, %95) <{mask = array<i32: 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %381 = "llvm.fmul"(%378, %380) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %382 = "llvm.load"(%122) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
      %383 = "llvm.fpext"(%382) : (vector<64xbf16>) -> vector<64xf32>
      %384 = "llvm.fmul"(%381, %383) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %385 = "llvm.fptrunc"(%384) : (vector<64xf32>) -> vector<64xbf16>
      "llvm.store"(%385, %123) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xbf16>, !llvm.ptr) -> ()
      "llvm.cond_br"(%193)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %386 = "llvm.load"(%121) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %387 = "llvm.icmp"(%386, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%387)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %388 = "llvm.load"(%123) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%388, %144) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %389 = "llvm.load"(%154) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %390 = "llvm.icmp"(%389, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%390)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %391 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
      %392 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %393 = "llvm.load"(%391) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%393, %392) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %394 = "llvm.load"(%160) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %395 = "llvm.icmp"(%394, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%395)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %396 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
      %397 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %398 = "llvm.load"(%396) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%398, %397) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %399 = "llvm.load"(%166) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %400 = "llvm.icmp"(%399, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%400)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %401 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
      %402 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %403 = "llvm.load"(%401) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%403, %402) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %404 = "llvm.load"(%172) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %405 = "llvm.icmp"(%404, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%405)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %406 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
      %407 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %408 = "llvm.load"(%406) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%408, %407) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %409 = "llvm.load"(%178) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %410 = "llvm.icmp"(%409, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%410)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %411 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
      %412 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %413 = "llvm.load"(%411) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%413, %412) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %414 = "llvm.load"(%184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %415 = "llvm.icmp"(%414, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%415)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %416 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
      %417 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %418 = "llvm.load"(%416) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%418, %417) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %419 = "llvm.load"(%190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %420 = "llvm.icmp"(%419, %109) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "llvm.cond_br"(%420)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %421 = "llvm.getelementptr"(%123) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
      %422 = "llvm.getelementptr"(%144) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
      %423 = "llvm.load"(%421) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%423, %422) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "llvm.br"()[^bb47] : () -> ()
    ^bb47:  // 2 preds: ^bb45, ^bb46
      "llvm.br"()[^bb48] : () -> ()
    ^bb48:  // 2 preds: ^bb30, ^bb47
      "llvm.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
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
