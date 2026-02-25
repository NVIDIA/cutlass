!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "((1,(4,4))):((0,(1,?{i64})))">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %139 = "cute.static"() : () -> !cute.layout<"(4,32):(32,1)">
      %140 = "cute.static"() : () -> !cute.layout<"(4,4):(4,1)">
      %141 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %142 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %143 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %144 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %145 = "cute.deref_arith_tuple_iter"(%144) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %146:2 = "cute.get_leaves"(%145) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %147 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %148 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %149 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %150 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %151 = "cute.deref_arith_tuple_iter"(%150) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %152:2 = "cute.get_leaves"(%151) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %153 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %154 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %155 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %156 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %157 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %158 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %159 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %160 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %161 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %162 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %163 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %164 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %165 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %166 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %167 = "cute.make_coord"(%164) : (i32) -> !cute.coord<"((_,_),?)">
      %168 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %169 = "cute.slice"(%168, %167) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %170 = "cute.crd2idx"(%167, %168) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %171 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %172 = "cute.add_offset"(%171, %170) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %173 = "cute.make_view"(%172, %169) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %174 = "cute.get_iter"(%173) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %175 = "cute.get_iter"(%173) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %176 = "cute.make_coord"(%164) : (i32) -> !cute.coord<"((_,_),?)">
      %177 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %178 = "cute.slice"(%177, %176) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %179 = "cute.crd2idx"(%176, %177) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %180 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %181 = "cute.add_offset"(%180, %179) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %182 = "cute.make_view"(%181, %178) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %183 = "cute.get_iter"(%182) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %184 = "cute.get_iter"(%182) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %185 = "cute.make_coord"(%164) : (i32) -> !cute.coord<"((_,_),?)">
      %186 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %187 = "cute.slice"(%186, %185) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %188 = "cute.crd2idx"(%185, %186) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %189 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %190 = "cute.add_offset"(%189, %188) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %191 = "cute.make_view"(%190, %187) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %192 = "cute.get_iter"(%191) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %193 = "cute.get_iter"(%191) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %194 = "cute.make_coord"(%164) : (i32) -> !cute.coord<"((_,_),?)">
      %195 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %196 = "cute.crd2idx"(%194, %195) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %197 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %198 = "cute.add_offset"(%197, %196) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %199 = "cute.make_view"(%198) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %200 = "cute.get_iter"(%199) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %201 = "cute.deref_arith_tuple_iter"(%200) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %202:2 = "cute.get_leaves"(%201) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %203 = "cute.get_scalars"(%202#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %204 = "cute.get_scalars"(%202#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %205 = "cute.get_iter"(%199) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %206 = "cute.deref_arith_tuple_iter"(%205) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %207:2 = "cute.get_leaves"(%206) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %208 = "cute.get_scalars"(%207#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %209 = "cute.get_scalars"(%207#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %210 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %211 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %212 = "cute.raked_product"(%139, %140) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %213 = "cute.size"(%139) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %214 = "cute.get_leaves"(%213) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %215 = "cute.size"(%140) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %216 = "cute.get_leaves"(%215) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %217 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %218 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %219 = "cute.right_inverse"(%212) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %220 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %221 = "cute.get_shape"(%212) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %222:4 = "cute.get_leaves"(%221) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %223 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %224 = "cute.tuple.product_each"(%223) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %225:2 = "cute.get_leaves"(%224) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %226 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %227 = "cute.tuple.product_each"(%226) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %228:2 = "cute.get_leaves"(%227) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %229 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %230 = "cute.make_tiled_copy"(%210) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %231 = "cute.raked_product"(%139, %140) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %232 = "cute.size"(%139) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %233 = "cute.get_leaves"(%232) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %234 = "cute.size"(%140) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %235 = "cute.get_leaves"(%234) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %236 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %237 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %238 = "cute.right_inverse"(%231) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %239 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %240 = "cute.get_shape"(%231) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %241:4 = "cute.get_leaves"(%240) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %242 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %243 = "cute.tuple.product_each"(%242) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %244:2 = "cute.get_leaves"(%243) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %245 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %246 = "cute.tuple.product_each"(%245) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %247:2 = "cute.get_leaves"(%246) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %248 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %249 = "cute.make_tiled_copy"(%210) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %250 = "cute.raked_product"(%139, %140) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %251 = "cute.size"(%139) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %252 = "cute.get_leaves"(%251) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %253 = "cute.size"(%140) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %254 = "cute.get_leaves"(%253) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %255 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %256 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %257 = "cute.right_inverse"(%250) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %258 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %259 = "cute.get_shape"(%250) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %260:4 = "cute.get_leaves"(%259) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %261 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %262 = "cute.tuple.product_each"(%261) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %263:2 = "cute.get_leaves"(%262) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %264 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %265 = "cute.tuple.product_each"(%264) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %266:2 = "cute.get_leaves"(%265) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %267 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %268 = "cute.make_tiled_copy"(%211) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %269 = "cute.make_coord"(%161) : (i32) -> !cute.coord<"?">
      %270 = "cute.tiled.copy.partition_S"(%230, %173, %269) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %271 = "cute.get_iter"(%270) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %272 = "cute.make_coord"(%161) : (i32) -> !cute.coord<"?">
      %273 = "cute.tiled.copy.partition_S"(%249, %182, %272) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %274 = "cute.get_iter"(%273) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %275 = "cute.make_coord"(%161) : (i32) -> !cute.coord<"?">
      %276 = "cute.tiled.copy.partition_S"(%268, %191, %275) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %277 = "cute.get_iter"(%276) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %278 = "cute.get_layout"(%270) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %279 = "cute.make_layout_like"(%278) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %280 = "cute.memref.alloca"(%279) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %281 = "cute.get_iter"(%280) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %282 = "cute.get_iter"(%280) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %283 = "cute.get_layout"(%273) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %284 = "cute.make_layout_like"(%283) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %285 = "cute.memref.alloca"(%284) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %286 = "cute.get_iter"(%285) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %287 = "cute.get_iter"(%285) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %288 = "cute.get_layout"(%276) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %289 = "cute.make_layout_like"(%288) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %290 = "cute.memref.alloca"(%289) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %291 = "cute.get_iter"(%290) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %292 = "cute.get_iter"(%290) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %293 = "cute.make_coord"(%161) : (i32) -> !cute.coord<"?">
      %294 = "cute.tiled.copy.partition_S"(%268, %199, %293) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %295 = "cute.get_iter"(%294) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %296 = "cute.deref_arith_tuple_iter"(%295) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %297:2 = "cute.get_leaves"(%296) : (!cute.int_tuple<"(?{div=4},?{div=4})">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">)
      %298 = "cute.get_scalars"(%297#0) : (!cute.int_tuple<"?{div=4}">) -> i32
      %299 = "cute.get_scalars"(%297#1) : (!cute.int_tuple<"?{div=4}">) -> i32
      %300 = "cute.get_layout"(%294) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %301 = "cute.get_shape"(%300) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %302:5 = "cute.get_leaves"(%301) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %303 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %304 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %305 = "cute.memref.alloca"(%304) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %306 = "cute.get_iter"(%305) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %307 = "cute.get_iter"(%305) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %308 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %309 = "cute.size"(%308) <{mode = array<i32>}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %310 = "cute.get_leaves"(%309) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %311 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %312 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %313 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %314 = "scf.for"(%311, %312, %313, %305) ({
      ^bb0(%arg12: i32, %arg13: !memref_rmem_i8_):
        %657 = "cute.get_iter"(%arg13) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %658 = "cute.get_iter"(%arg13) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %659 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"?">
        %660 = "cute.get_layout"(%294) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %661 = "cute.crd2idx"(%659, %660) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %662 = "cute.get_iter"(%294) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
        %663 = "cute.add_offset"(%662, %661) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %664 = "cute.make_view"(%663) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
        %665 = "cute.get_iter"(%664) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %666 = "cute.deref_arith_tuple_iter"(%665) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %667:2 = "cute.get_leaves"(%666) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %668 = "cute.get_scalars"(%667#0) : (!cute.int_tuple<"?">) -> i32
        %669 = "cute.get_scalars"(%667#1) : (!cute.int_tuple<"?">) -> i32
        %670 = "cute.get_iter"(%664) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %671 = "cute.deref_arith_tuple_iter"(%670) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %672:2 = "cute.get_leaves"(%671) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %673 = "cute.get_scalars"(%672#0) : (!cute.int_tuple<"?">) -> i32
        %674 = "cute.get_scalars"(%672#1) : (!cute.int_tuple<"?">) -> i32
        %675 = "cute.get_iter"(%664) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %676 = "cute.deref_arith_tuple_iter"(%675) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %677:2 = "cute.get_leaves"(%676) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %678 = "cute.get_scalars"(%677#0) : (!cute.int_tuple<"?">) -> i32
        %679 = "cute.get_scalars"(%677#1) : (!cute.int_tuple<"?">) -> i32
        %680 = "cute.make_coord"(%677#0, %677#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %681 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %682 = "cute.elem_less"(%680, %681) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %683 = "arith.extui"(%682) : (i1) -> i8
        %684 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg13, %684, %683) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg13) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %315 = "cute.get_iter"(%314) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %316 = "cute.get_iter"(%314) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %317 = "cute.get_iter"(%314) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %318 = "cute.get_layout"(%270) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %319 = "cute.get_shape"(%318) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %320:5 = "cute.get_leaves"(%319) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %321 = "cute.get_layout"(%280) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %322 = "cute.get_shape"(%321) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %323:5 = "cute.get_leaves"(%322) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %324 = "cute.get_layout"(%270) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %325 = "cute.make_shape"() : () -> !cute.shape<"1">
      %326 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %327 = "cute.append_to_rank"(%324, %326) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %328 = "cute.make_view"(%271, %327) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %329 = "cute.get_iter"(%328) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %330 = "cute.get_layout"(%328) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %331 = "cute.get_shape"(%330) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %332:5 = "cute.get_leaves"(%331) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %333 = "cute.get_layout"(%328) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %334 = "cute.get_shape"(%333) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %335:5 = "cute.get_leaves"(%334) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %336 = "cute.get_iter"(%328) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %337 = "cute.get_layout"(%328) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %338 = "cute.get_scalars"(%337) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %339 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %340 = "cute.make_stride"(%338) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %341 = "cute.make_layout"(%339, %340) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %342 = "cute.make_view"(%336, %341) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %343 = "cute.get_iter"(%342) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %344 = "cute.get_iter"(%342) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %345 = "cute.get_layout"(%280) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %346 = "cute.make_shape"() : () -> !cute.shape<"1">
      %347 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %348 = "cute.append_to_rank"(%345, %347) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %349 = "cute.make_view"(%282, %348) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %350 = "cute.get_iter"(%349) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %351 = "cute.get_layout"(%349) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %352 = "cute.get_shape"(%351) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %353:5 = "cute.get_leaves"(%352) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %354 = "cute.get_layout"(%349) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %355 = "cute.get_shape"(%354) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %356:5 = "cute.get_leaves"(%355) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %357 = "cute.get_iter"(%349) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %358 = "cute.make_view"(%357) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %359 = "cute.get_iter"(%358) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %360 = "cute.get_iter"(%358) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %361 = "cute.get_layout"(%314) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %362 = "cute.make_shape"() : () -> !cute.shape<"1">
      %363 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %364 = "cute.append_to_rank"(%361, %363) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %365 = "cute.make_view"(%317, %364) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %366 = "cute.get_iter"(%365) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %367 = "cute.get_layout"(%365) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %368 = "cute.get_shape"(%367) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %369:5 = "cute.get_leaves"(%368) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %370 = "cute.get_layout"(%365) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %371 = "cute.get_shape"(%370) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %372:5 = "cute.get_leaves"(%371) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %373 = "cute.get_iter"(%365) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %374 = "cute.make_view"(%373) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %375 = "cute.get_iter"(%374) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %376 = "cute.get_iter"(%374) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %377 = "cute.get_layout"(%342) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %378 = "cute.get_shape"(%377) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %379:5 = "cute.get_leaves"(%378) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %380 = "cute.get_layout"(%358) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %381 = "cute.get_shape"(%380) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %382:5 = "cute.get_leaves"(%381) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %383 = "cute.get_layout"(%342) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %384 = "cute.size"(%383) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %385 = "cute.get_leaves"(%384) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %386 = "cute.get_layout"(%358) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %387 = "cute.size"(%386) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %388 = "cute.get_leaves"(%387) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %389 = "cute.static"() : () -> !cute.layout<"1:0">
      %390 = "cute.get_iter"(%342) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %391 = "cute.get_iter"(%358) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %392 = "cute.get_layout"(%342) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %393 = "cute.get_layout"(%358) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %394 = "cute.append_to_rank"(%392, %389) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %395 = "cute.append_to_rank"(%393, %389) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %396 = "cute.get_scalars"(%394) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %397 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %398 = "cute.make_stride"(%396) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %399 = "cute.make_layout"(%397, %398) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %400 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %401 = "cute.get_iter"(%374) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %402 = "cute.get_layout"(%374) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %403 = "cute.append_to_rank"(%402, %389) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %404 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %405 = "cute.size"(%399) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %406 = "cute.get_scalars"(%405) : (!cute.int_tuple<"1">) -> i32
      %407 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %408 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%407, %406, %408) ({
      ^bb0(%arg11: i32):
        %644 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %645 = "cute.slice"(%399, %644) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %646 = "cute.crd2idx"(%644, %399) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %647 = "cute.add_offset"(%390, %646) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %648 = "cute.make_view"(%647, %645) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %649 = "cute.slice"(%400, %644) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %650 = "cute.crd2idx"(%644, %400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %651 = "cute.add_offset"(%391, %650) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %652 = "cute.make_view"(%651, %649) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %653 = "cute.slice"(%404, %644) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %654 = "cute.crd2idx"(%644, %404) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %655 = "cute.add_offset"(%401, %654) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %656 = "cute.make_view"(%655, %653) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        "cute.copy_atom_call"(%210, %648, %652, %656) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %409 = "cute.get_layout"(%273) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %410 = "cute.get_shape"(%409) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %411:5 = "cute.get_leaves"(%410) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %412 = "cute.get_layout"(%285) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %413 = "cute.get_shape"(%412) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %414:5 = "cute.get_leaves"(%413) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %415 = "cute.get_layout"(%273) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %416 = "cute.make_shape"() : () -> !cute.shape<"1">
      %417 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %418 = "cute.append_to_rank"(%415, %417) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %419 = "cute.make_view"(%274, %418) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %420 = "cute.get_iter"(%419) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %421 = "cute.get_layout"(%419) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %422 = "cute.get_shape"(%421) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %423:5 = "cute.get_leaves"(%422) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %424 = "cute.get_layout"(%419) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %425 = "cute.get_shape"(%424) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %426:5 = "cute.get_leaves"(%425) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %427 = "cute.get_iter"(%419) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %428 = "cute.get_layout"(%419) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %429 = "cute.get_scalars"(%428) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %430 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %431 = "cute.make_stride"(%429) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %432 = "cute.make_layout"(%430, %431) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %433 = "cute.make_view"(%427, %432) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %434 = "cute.get_iter"(%433) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %435 = "cute.get_iter"(%433) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %436 = "cute.get_layout"(%285) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %437 = "cute.make_shape"() : () -> !cute.shape<"1">
      %438 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %439 = "cute.append_to_rank"(%436, %438) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %440 = "cute.make_view"(%287, %439) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %441 = "cute.get_iter"(%440) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %442 = "cute.get_layout"(%440) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %443 = "cute.get_shape"(%442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %444:5 = "cute.get_leaves"(%443) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %445 = "cute.get_layout"(%440) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %446 = "cute.get_shape"(%445) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %447:5 = "cute.get_leaves"(%446) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %448 = "cute.get_iter"(%440) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %449 = "cute.make_view"(%448) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %450 = "cute.get_iter"(%449) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %451 = "cute.get_iter"(%449) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %452 = "cute.get_layout"(%314) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %453 = "cute.make_shape"() : () -> !cute.shape<"1">
      %454 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %455 = "cute.append_to_rank"(%452, %454) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %456 = "cute.make_view"(%317, %455) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %457 = "cute.get_iter"(%456) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %458 = "cute.get_layout"(%456) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %459 = "cute.get_shape"(%458) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %460:5 = "cute.get_leaves"(%459) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %461 = "cute.get_layout"(%456) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %462 = "cute.get_shape"(%461) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %463:5 = "cute.get_leaves"(%462) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %464 = "cute.get_iter"(%456) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %465 = "cute.make_view"(%464) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %466 = "cute.get_iter"(%465) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %467 = "cute.get_iter"(%465) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %468 = "cute.get_layout"(%433) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %469 = "cute.get_shape"(%468) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %470:5 = "cute.get_leaves"(%469) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %471 = "cute.get_layout"(%449) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %472 = "cute.get_shape"(%471) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %473:5 = "cute.get_leaves"(%472) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %474 = "cute.get_layout"(%433) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %475 = "cute.size"(%474) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %476 = "cute.get_leaves"(%475) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %477 = "cute.get_layout"(%449) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %478 = "cute.size"(%477) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %479 = "cute.get_leaves"(%478) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %480 = "cute.static"() : () -> !cute.layout<"1:0">
      %481 = "cute.get_iter"(%433) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %482 = "cute.get_iter"(%449) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %483 = "cute.get_layout"(%433) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %484 = "cute.get_layout"(%449) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %485 = "cute.append_to_rank"(%483, %480) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %486 = "cute.append_to_rank"(%484, %480) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %487 = "cute.get_scalars"(%485) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %488 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %489 = "cute.make_stride"(%487) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %490 = "cute.make_layout"(%488, %489) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %491 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %492 = "cute.get_iter"(%465) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %493 = "cute.get_layout"(%465) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %494 = "cute.append_to_rank"(%493, %480) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %495 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %496 = "cute.size"(%490) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %497 = "cute.get_scalars"(%496) : (!cute.int_tuple<"1">) -> i32
      %498 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %499 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%498, %497, %499) ({
      ^bb0(%arg10: i32):
        %631 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
        %632 = "cute.slice"(%490, %631) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %633 = "cute.crd2idx"(%631, %490) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %634 = "cute.add_offset"(%481, %633) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %635 = "cute.make_view"(%634, %632) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %636 = "cute.slice"(%491, %631) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %637 = "cute.crd2idx"(%631, %491) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %638 = "cute.add_offset"(%482, %637) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %639 = "cute.make_view"(%638, %636) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %640 = "cute.slice"(%495, %631) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %641 = "cute.crd2idx"(%631, %495) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %642 = "cute.add_offset"(%492, %641) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %643 = "cute.make_view"(%642, %640) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        "cute.copy_atom_call"(%210, %635, %639, %643) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %500 = "cute.get_layout"(%280) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %501 = "cute.get_shape"(%500) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %502:5 = "cute.get_leaves"(%501) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %503 = "cute.memref.load_vec"(%280) : (!memref_rmem_f32_) -> vector<16xf32>
      %504 = "cute.get_layout"(%280) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %505 = "cute.get_shape"(%504) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %506:5 = "cute.get_leaves"(%505) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %507 = "cute.get_layout"(%285) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %508 = "cute.get_shape"(%507) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %509:5 = "cute.get_leaves"(%508) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %510 = "cute.memref.load_vec"(%285) : (!memref_rmem_f32_) -> vector<16xf32>
      %511 = "cute.get_layout"(%285) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %512 = "cute.get_shape"(%511) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %513:5 = "cute.get_leaves"(%512) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %514 = "arith.addf"(%503, %510) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      %515 = "cute.get_layout"(%290) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %516 = "cute.get_shape"(%515) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %517:5 = "cute.get_leaves"(%516) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %518 = "cute.get_layout"(%290) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %519 = "cute.get_shape"(%518) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %520:5 = "cute.get_leaves"(%519) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %521 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %522 = "cute.size"(%521) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %523 = "cute.get_leaves"(%522) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %524 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %525 = "cute.size"(%524) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %526 = "cute.get_leaves"(%525) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%514, %290) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %527 = "cute.get_layout"(%290) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %528 = "cute.get_shape"(%527) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %529:5 = "cute.get_leaves"(%528) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %530 = "cute.get_layout"(%276) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %531 = "cute.get_shape"(%530) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %532:5 = "cute.get_leaves"(%531) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %533 = "cute.get_layout"(%290) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %534 = "cute.make_shape"() : () -> !cute.shape<"1">
      %535 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %536 = "cute.append_to_rank"(%533, %535) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %537 = "cute.make_view"(%292, %536) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %538 = "cute.get_iter"(%537) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %539 = "cute.get_layout"(%537) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %540 = "cute.get_shape"(%539) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %541:5 = "cute.get_leaves"(%540) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %542 = "cute.get_layout"(%537) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %543 = "cute.get_shape"(%542) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %544:5 = "cute.get_leaves"(%543) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %545 = "cute.get_iter"(%537) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %546 = "cute.make_view"(%545) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %547 = "cute.get_iter"(%546) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %548 = "cute.get_iter"(%546) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %549 = "cute.get_layout"(%276) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %550 = "cute.make_shape"() : () -> !cute.shape<"1">
      %551 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %552 = "cute.append_to_rank"(%549, %551) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %553 = "cute.make_view"(%277, %552) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %554 = "cute.get_iter"(%553) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %555 = "cute.get_layout"(%553) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %556 = "cute.get_shape"(%555) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %557:5 = "cute.get_leaves"(%556) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %558 = "cute.get_layout"(%553) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %559 = "cute.get_shape"(%558) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %560:5 = "cute.get_leaves"(%559) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %561 = "cute.get_iter"(%553) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %562 = "cute.get_layout"(%553) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %563 = "cute.get_scalars"(%562) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %564 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %565 = "cute.make_stride"(%563) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %566 = "cute.make_layout"(%564, %565) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %567 = "cute.make_view"(%561, %566) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %568 = "cute.get_iter"(%567) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %569 = "cute.get_iter"(%567) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %570 = "cute.get_layout"(%314) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %571 = "cute.make_shape"() : () -> !cute.shape<"1">
      %572 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %573 = "cute.append_to_rank"(%570, %572) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %574 = "cute.make_view"(%317, %573) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %575 = "cute.get_iter"(%574) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %576 = "cute.get_layout"(%574) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %577 = "cute.get_shape"(%576) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %578:5 = "cute.get_leaves"(%577) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %579 = "cute.get_layout"(%574) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %580 = "cute.get_shape"(%579) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %581:5 = "cute.get_leaves"(%580) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %582 = "cute.get_iter"(%574) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %583 = "cute.make_view"(%582) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %584 = "cute.get_iter"(%583) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %585 = "cute.get_iter"(%583) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %586 = "cute.get_layout"(%546) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %587 = "cute.get_shape"(%586) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %588:5 = "cute.get_leaves"(%587) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %589 = "cute.get_layout"(%567) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %590 = "cute.get_shape"(%589) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %591:5 = "cute.get_leaves"(%590) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %592 = "cute.get_layout"(%546) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %593 = "cute.size"(%592) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %594 = "cute.get_leaves"(%593) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %595 = "cute.get_layout"(%567) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %596 = "cute.size"(%595) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %597 = "cute.get_leaves"(%596) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %598 = "cute.static"() : () -> !cute.layout<"1:0">
      %599 = "cute.get_iter"(%546) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %600 = "cute.get_iter"(%567) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %601 = "cute.get_layout"(%546) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %602 = "cute.get_layout"(%567) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %603 = "cute.append_to_rank"(%601, %598) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %604 = "cute.append_to_rank"(%602, %598) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %605 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %606 = "cute.get_scalars"(%604) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %607 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %608 = "cute.make_stride"(%606) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %609 = "cute.make_layout"(%607, %608) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %610 = "cute.get_iter"(%583) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %611 = "cute.get_layout"(%583) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %612 = "cute.append_to_rank"(%611, %598) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %613 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %614 = "cute.size"(%605) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %615 = "cute.get_scalars"(%614) : (!cute.int_tuple<"1">) -> i32
      %616 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %617 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%616, %615, %617) ({
      ^bb0(%arg9: i32):
        %618 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"(_,?)">
        %619 = "cute.slice"(%605, %618) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %620 = "cute.crd2idx"(%618, %605) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %621 = "cute.add_offset"(%599, %620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %622 = "cute.make_view"(%621, %619) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %623 = "cute.slice"(%609, %618) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %624 = "cute.crd2idx"(%618, %609) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %625 = "cute.add_offset"(%600, %624) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %626 = "cute.make_view"(%625, %623) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %627 = "cute.slice"(%613, %618) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %628 = "cute.crd2idx"(%618, %613) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %629 = "cute.add_offset"(%610, %628) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %630 = "cute.make_view"(%629, %627) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        "cute.copy_atom_call"(%211, %622, %626, %630) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_2, !memref_gmem_f32_4, !memref_rmem_i8_2) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_5, !memref_gmem_f32_5, !memref_gmem_f32_5) -> i32, sym_name = "cutlass_elementwise_add_tensor00644_03711_00110_04851_03515_08385_15093_00759_05930_07060_10713_18194_00944_06791_03214_06920_01900_16902_02636_10262_09792_12286_01389_04307_02417_"}> ({
  ^bb0(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %2 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %4 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %5 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %6 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %7 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %8 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %9 = "cute.make_shape"() : () -> !cute.shape<"(4,32)">
    %10 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
    %11 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,32):(32,1)">
    %12 = "cute.make_shape"() : () -> !cute.shape<"(4,4)">
    %13 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
    %14 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,4):(4,1)">
    %15 = "cute.raked_product"(%11, %14) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %16 = "cute.size"(%11) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %17 = "cute.get_leaves"(%16) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %18 = "cute.size"(%14) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %19 = "cute.get_leaves"(%18) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
    %20 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
    %21 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
    %22 = "cute.right_inverse"(%15) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %23 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %24 = "cute.get_shape"(%15) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %25:4 = "cute.get_leaves"(%24) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
    %26 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %27 = "cute.tuple.product_each"(%26) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %28:2 = "cute.get_leaves"(%27) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
    %29 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %30 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %31 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %32:3 = "cute.get_scalars"(%31) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %33 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %34 = "arith.ceildivsi"(%32#0, %33) : (i32, i32) -> i32
    %35 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %36 = "arith.muli"(%32#2, %35) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %37 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %38 = "arith.ceildivsi"(%32#1, %37) : (i32, i32) -> i32
    %39 = "cute.make_shape"(%34, %38) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %40 = "cute.assume"(%36) : (i64) -> !cute.i64<divby 16>
    %41 = "cute.make_stride"(%32#2, %40) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %42 = "cute.make_layout"(%39, %41) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %43 = "cute.make_view"(%30, %42) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %44 = "cute.get_iter"(%43) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %45 = "cute.get_iter"(%43) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %46 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %47 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %48 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %49:3 = "cute.get_scalars"(%48) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %50 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %51 = "arith.ceildivsi"(%49#0, %50) : (i32, i32) -> i32
    %52 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %53 = "arith.muli"(%49#2, %52) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %54 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %55 = "arith.ceildivsi"(%49#1, %54) : (i32, i32) -> i32
    %56 = "cute.make_shape"(%51, %55) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %57 = "cute.assume"(%53) : (i64) -> !cute.i64<divby 16>
    %58 = "cute.make_stride"(%49#2, %57) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %59 = "cute.make_layout"(%56, %58) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %60 = "cute.make_view"(%47, %59) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %61 = "cute.get_iter"(%60) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %62 = "cute.get_iter"(%60) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %63 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %64 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %65 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %66:3 = "cute.get_scalars"(%65) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %67 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %68 = "arith.ceildivsi"(%66#0, %67) : (i32, i32) -> i32
    %69 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %70 = "arith.muli"(%66#2, %69) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %71 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %72 = "arith.ceildivsi"(%66#1, %71) : (i32, i32) -> i32
    %73 = "cute.make_shape"(%68, %72) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %74 = "cute.assume"(%70) : (i64) -> !cute.i64<divby 16>
    %75 = "cute.make_stride"(%66#2, %74) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %76 = "cute.make_layout"(%73, %75) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %77 = "cute.make_view"(%64, %76) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %78 = "cute.get_iter"(%77) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %79 = "cute.get_iter"(%77) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %80 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %81 = "cute.get_shape"(%80) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %82:2 = "cute.get_leaves"(%81) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %83 = "cute.to_int_tuple"(%82#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %84 = "cute.get_scalars"(%83) : (!cute.int_tuple<"?">) -> i32
    %85 = "cute.to_int_tuple"(%82#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %86 = "cute.get_scalars"(%85) : (!cute.int_tuple<"?">) -> i32
    %87 = "cute.make_shape"(%83, %85) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %88 = "cute.make_identity_tensor"(%87) : (!cute.shape<"(?,?)">) -> !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %89 = "cute.get_iter"(%88) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
    %90 = "cute.deref_arith_tuple_iter"(%89) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %91:2 = "cute.get_leaves"(%90) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %92 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %93 = "cute.get_iter"(%88) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
    %94 = "cute.get_layout"(%88) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %95:2 = "cute.get_scalars"(%94) <{only_dynamic}> : (!cute.layout<"(?,?):(1@0,1@1)">) -> (i32, i32)
    %96 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %97 = "arith.ceildivsi"(%95#0, %96) : (i32, i32) -> i32
    %98 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %99 = "arith.ceildivsi"(%95#1, %98) : (i32, i32) -> i32
    %100 = "cute.make_shape"(%97, %99) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %101 = "cute.make_stride"() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %102 = "cute.make_layout"(%100, %101) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %103 = "cute.make_view"(%93, %102) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %104 = "cute.get_iter"(%103) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
    %105 = "cute.deref_arith_tuple_iter"(%104) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %106:2 = "cute.get_leaves"(%105) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %107 = "cute.get_iter"(%103) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
    %108 = "cute.deref_arith_tuple_iter"(%107) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %109:2 = "cute.get_leaves"(%108) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %110 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %111 = "cute.get_shape"(%110) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %112:2 = "cute.get_leaves"(%111) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %113 = "cute.to_int_tuple"(%112#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %114 = "cute.get_scalars"(%113) : (!cute.int_tuple<"?">) -> i32
    %115 = "cute.to_int_tuple"(%112#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %116 = "cute.get_scalars"(%115) : (!cute.int_tuple<"?">) -> i32
    %117 = "cute.get_layout"(%77) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %118 = "cute.size"(%117) <{mode = array<i32: 1>}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %119 = "cute.get_leaves"(%118) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %120 = "cute.get_scalars"(%119) : (!cute.int_tuple<"?">) -> i32
    %121 = "cute.size"(%23) <{mode = array<i32: 0>}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %122 = "cute.get_leaves"(%121) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %123 = "cute.get_layout"(%43) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %124 = "cute.get_layout"(%60) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %125 = "cute.get_layout"(%77) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %126 = "cute.get_layout"(%103) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %127 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %128 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %129 = "cuda.cast"(%128) : (i64) -> !cuda.stream
    %130 = "arith.extsi"(%127) : (i32) -> i64
    %131 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %132 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %133 = "cuda.launch_cfg.create"(%131, %132, %132, %130, %120, %132, %132, %129) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %134 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%133, %134) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %135 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%133, %135) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %136 = "cuda.launch_ex"(%133, %43, %60, %77, %103, %114, %116) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %137 = "cuda.cast"(%136) : (!cuda.result) -> i32
    "cuda.return_if_error"(%137) : (i32) -> ()
    %138 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%138) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
