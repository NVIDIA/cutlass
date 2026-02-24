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
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !memref_gmem_f32_, %arg7: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg8: i32, %arg9: i32):
      %137 = "cute.static"() : () -> !cute.layout<"(4,32):(32,1)">
      %138 = "cute.static"() : () -> !cute.layout<"(4,4):(4,1)">
      %139 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %140 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %141 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %142 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %143 = "cute.deref_arith_tuple_iter"(%142) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %144:2 = "cute.get_leaves"(%143) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %145 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %146 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %147 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %148 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %149 = "cute.deref_arith_tuple_iter"(%148) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %150:2 = "cute.get_leaves"(%149) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %151 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %152 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %153 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %154 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %155 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %156 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %157 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %158 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %159 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %160 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %161 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %162 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %163 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %164 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %165 = "cute.make_coord"(%162) : (i32) -> !cute.coord<"((_,_),?)">
      %166 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %167 = "cute.slice"(%166, %165) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %168 = "cute.crd2idx"(%165, %166) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %169 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %170 = "cute.add_offset"(%169, %168) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %171 = "cute.make_view"(%170, %167) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %172 = "cute.get_iter"(%171) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %173 = "cute.get_iter"(%171) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %174 = "cute.make_coord"(%162) : (i32) -> !cute.coord<"((_,_),?)">
      %175 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %176 = "cute.slice"(%175, %174) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %177 = "cute.crd2idx"(%174, %175) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %178 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %179 = "cute.add_offset"(%178, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %180 = "cute.make_view"(%179, %176) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %181 = "cute.get_iter"(%180) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %182 = "cute.get_iter"(%180) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %183 = "cute.make_coord"(%162) : (i32) -> !cute.coord<"((_,_),?)">
      %184 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %185 = "cute.slice"(%184, %183) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %186 = "cute.crd2idx"(%183, %184) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %187 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %188 = "cute.add_offset"(%187, %186) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %189 = "cute.make_view"(%188, %185) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %190 = "cute.get_iter"(%189) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %191 = "cute.get_iter"(%189) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %192 = "cute.make_coord"(%162) : (i32) -> !cute.coord<"((_,_),?)">
      %193 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %194 = "cute.crd2idx"(%192, %193) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %195 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %196 = "cute.add_offset"(%195, %194) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %197 = "cute.make_view"(%196) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %198 = "cute.get_iter"(%197) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %199 = "cute.deref_arith_tuple_iter"(%198) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %200:2 = "cute.get_leaves"(%199) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %201 = "cute.get_scalars"(%200#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %202 = "cute.get_scalars"(%200#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %203 = "cute.get_iter"(%197) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %204 = "cute.deref_arith_tuple_iter"(%203) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %205:2 = "cute.get_leaves"(%204) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %206 = "cute.get_scalars"(%205#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %207 = "cute.get_scalars"(%205#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %208 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %209 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %210 = "cute.raked_product"(%137, %138) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %211 = "cute.size"(%137) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %212 = "cute.get_leaves"(%211) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %213 = "cute.size"(%138) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %214 = "cute.get_leaves"(%213) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %215 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %216 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %217 = "cute.right_inverse"(%210) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %218 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %219 = "cute.get_shape"(%210) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %220:4 = "cute.get_leaves"(%219) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %221 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %222 = "cute.tuple.product_each"(%221) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %223:2 = "cute.get_leaves"(%222) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %224 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %225 = "cute.tuple.product_each"(%224) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %226:2 = "cute.get_leaves"(%225) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %227 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %228 = "cute.make_tiled_copy"(%208) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %229 = "cute.raked_product"(%137, %138) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %230 = "cute.size"(%137) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %231 = "cute.get_leaves"(%230) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %232 = "cute.size"(%138) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %233 = "cute.get_leaves"(%232) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %234 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %235 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %236 = "cute.right_inverse"(%229) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %237 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %238 = "cute.get_shape"(%229) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %239:4 = "cute.get_leaves"(%238) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %240 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %241 = "cute.tuple.product_each"(%240) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %242:2 = "cute.get_leaves"(%241) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %243 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %244 = "cute.tuple.product_each"(%243) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %245:2 = "cute.get_leaves"(%244) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %246 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %247 = "cute.make_tiled_copy"(%208) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %248 = "cute.raked_product"(%137, %138) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %249 = "cute.size"(%137) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %250 = "cute.get_leaves"(%249) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %251 = "cute.size"(%138) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %252 = "cute.get_leaves"(%251) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %253 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %254 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,16):(1,128)">
      %255 = "cute.right_inverse"(%248) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %256 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %257 = "cute.get_shape"(%248) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %258:4 = "cute.get_leaves"(%257) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %259 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %260 = "cute.tuple.product_each"(%259) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %261:2 = "cute.get_leaves"(%260) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %262 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %263 = "cute.tuple.product_each"(%262) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %264:2 = "cute.get_leaves"(%263) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %265 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %266 = "cute.make_tiled_copy"(%209) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %267 = "cute.make_coord"(%159) : (i32) -> !cute.coord<"?">
      %268 = "cute.tiled.copy.partition_S"(%228, %171, %267) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %269 = "cute.get_iter"(%268) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %270 = "cute.make_coord"(%159) : (i32) -> !cute.coord<"?">
      %271 = "cute.tiled.copy.partition_S"(%247, %180, %270) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %272 = "cute.get_iter"(%271) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %273 = "cute.make_coord"(%159) : (i32) -> !cute.coord<"?">
      %274 = "cute.tiled.copy.partition_S"(%266, %189, %273) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %275 = "cute.get_iter"(%274) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %276 = "cute.get_layout"(%268) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %277 = "cute.make_layout_like"(%276) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %278 = "cute.memref.alloca"(%277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %279 = "cute.get_iter"(%278) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %280 = "cute.get_iter"(%278) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %281 = "cute.get_layout"(%271) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %282 = "cute.make_layout_like"(%281) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %283 = "cute.memref.alloca"(%282) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %284 = "cute.get_iter"(%283) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %285 = "cute.get_iter"(%283) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %286 = "cute.get_layout"(%274) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %287 = "cute.make_layout_like"(%286) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %288 = "cute.memref.alloca"(%287) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %289 = "cute.get_iter"(%288) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %290 = "cute.get_iter"(%288) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %291 = "cute.make_coord"(%159) : (i32) -> !cute.coord<"?">
      %292 = "cute.tiled.copy.partition_S"(%266, %197, %291) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %293 = "cute.get_iter"(%292) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %294 = "cute.deref_arith_tuple_iter"(%293) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %295:2 = "cute.get_leaves"(%294) : (!cute.int_tuple<"(?{div=4},?{div=4})">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">)
      %296 = "cute.get_scalars"(%295#0) : (!cute.int_tuple<"?{div=4}">) -> i32
      %297 = "cute.get_scalars"(%295#1) : (!cute.int_tuple<"?{div=4}">) -> i32
      %298 = "cute.get_layout"(%292) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %299 = "cute.get_shape"(%298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %300:5 = "cute.get_leaves"(%299) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %301 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %302 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %303 = "cute.memref.alloca"(%302) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %304 = "cute.get_iter"(%303) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %305 = "cute.get_iter"(%303) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %306 = "cute.get_layout"(%303) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %307 = "cute.size"(%306) <{mode = array<i32>}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %308 = "cute.get_leaves"(%307) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %309 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %310 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %311 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %312 = "scf.for"(%309, %310, %311, %303) ({
      ^bb0(%arg22: i32, %arg23: !memref_rmem_i8_):
        %887 = "cute.get_iter"(%arg23) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %888 = "cute.get_iter"(%arg23) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %889 = "cute.make_coord"(%arg22) : (i32) -> !cute.coord<"?">
        %890 = "cute.get_layout"(%292) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %891 = "cute.crd2idx"(%889, %890) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %892 = "cute.get_iter"(%292) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
        %893 = "cute.add_offset"(%892, %891) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %894 = "cute.make_view"(%893) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
        %895 = "cute.get_iter"(%894) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %896 = "cute.deref_arith_tuple_iter"(%895) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %897:2 = "cute.get_leaves"(%896) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %898 = "cute.get_scalars"(%897#0) : (!cute.int_tuple<"?">) -> i32
        %899 = "cute.get_scalars"(%897#1) : (!cute.int_tuple<"?">) -> i32
        %900 = "cute.get_iter"(%894) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %901 = "cute.deref_arith_tuple_iter"(%900) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %902:2 = "cute.get_leaves"(%901) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %903 = "cute.get_scalars"(%902#0) : (!cute.int_tuple<"?">) -> i32
        %904 = "cute.get_scalars"(%902#1) : (!cute.int_tuple<"?">) -> i32
        %905 = "cute.get_iter"(%894) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %906 = "cute.deref_arith_tuple_iter"(%905) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %907:2 = "cute.get_leaves"(%906) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %908 = "cute.get_scalars"(%907#0) : (!cute.int_tuple<"?">) -> i32
        %909 = "cute.get_scalars"(%907#1) : (!cute.int_tuple<"?">) -> i32
        %910 = "cute.make_coord"(%907#0, %907#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %911 = "cute.make_coord"(%arg8, %arg9) : (i32, i32) -> !cute.coord<"(?,?)">
        %912 = "cute.elem_less"(%910, %911) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %913 = "arith.extui"(%912) : (i1) -> i8
        %914 = "cute.make_coord"(%arg22) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg23, %914, %913) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg23) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %313 = "cute.get_iter"(%312) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %314 = "cute.get_iter"(%312) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %315 = "cute.get_iter"(%312) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %316 = "arith.constant"() <{value = false}> : () -> i1
      "scf.if"(%316) ({
        %676 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %677 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %678 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%676, %677, %678) ({
        ^bb0(%arg19: i32):
          %679 = "cute.get_layout"(%268) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %680 = "cute.get_shape"(%679) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %681:5 = "cute.get_leaves"(%680) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %682 = "cute.get_layout"(%278) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %683 = "cute.get_shape"(%682) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %684:5 = "cute.get_leaves"(%683) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %685 = "cute.get_layout"(%268) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %686 = "cute.make_shape"() : () -> !cute.shape<"1">
          %687 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %688 = "cute.append_to_rank"(%685, %687) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %689 = "cute.make_view"(%269, %688) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %690 = "cute.get_iter"(%689) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %691 = "cute.get_layout"(%689) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %692 = "cute.get_shape"(%691) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %693:5 = "cute.get_leaves"(%692) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %694 = "cute.get_layout"(%689) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %695 = "cute.get_shape"(%694) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %696:5 = "cute.get_leaves"(%695) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %697 = "cute.get_iter"(%689) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %698 = "cute.get_layout"(%689) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %699 = "cute.get_scalars"(%698) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
          %700 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %701 = "cute.make_stride"(%699) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %702 = "cute.make_layout"(%700, %701) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %703 = "cute.make_view"(%697, %702) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
          %704 = "cute.get_iter"(%703) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %705 = "cute.get_iter"(%703) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %706 = "cute.get_layout"(%278) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %707 = "cute.make_shape"() : () -> !cute.shape<"1">
          %708 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %709 = "cute.append_to_rank"(%706, %708) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %710 = "cute.make_view"(%280, %709) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %711 = "cute.get_iter"(%710) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %712 = "cute.get_layout"(%710) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %713 = "cute.get_shape"(%712) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %714:5 = "cute.get_leaves"(%713) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %715 = "cute.get_layout"(%710) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %716 = "cute.get_shape"(%715) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %717:5 = "cute.get_leaves"(%716) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %718 = "cute.get_iter"(%710) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %719 = "cute.make_view"(%718) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
          %720 = "cute.get_iter"(%719) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %721 = "cute.get_iter"(%719) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %722 = "cute.get_layout"(%312) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %723 = "cute.make_shape"() : () -> !cute.shape<"1">
          %724 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %725 = "cute.append_to_rank"(%722, %724) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %726 = "cute.make_view"(%315, %725) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %727 = "cute.get_iter"(%726) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %728 = "cute.get_layout"(%726) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %729 = "cute.get_shape"(%728) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %730:5 = "cute.get_leaves"(%729) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %731 = "cute.get_layout"(%726) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %732 = "cute.get_shape"(%731) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %733:5 = "cute.get_leaves"(%732) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %734 = "cute.get_iter"(%726) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %735 = "cute.make_view"(%734) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
          %736 = "cute.get_iter"(%735) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %737 = "cute.get_iter"(%735) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %738 = "cute.get_layout"(%703) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %739 = "cute.get_shape"(%738) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %740:5 = "cute.get_leaves"(%739) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %741 = "cute.get_layout"(%719) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %742 = "cute.get_shape"(%741) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %743:5 = "cute.get_leaves"(%742) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %744 = "cute.get_layout"(%703) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %745 = "cute.size"(%744) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %746 = "cute.get_leaves"(%745) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %747 = "cute.get_layout"(%719) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %748 = "cute.size"(%747) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %749 = "cute.get_leaves"(%748) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %750 = "cute.static"() : () -> !cute.layout<"1:0">
          %751 = "cute.get_iter"(%703) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %752 = "cute.get_iter"(%719) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %753 = "cute.get_layout"(%703) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %754 = "cute.get_layout"(%719) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %755 = "cute.append_to_rank"(%753, %750) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %756 = "cute.append_to_rank"(%754, %750) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %757 = "cute.get_scalars"(%755) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
          %758 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %759 = "cute.make_stride"(%757) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %760 = "cute.make_layout"(%758, %759) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %761 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %762 = "cute.get_iter"(%735) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %763 = "cute.get_layout"(%735) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %764 = "cute.append_to_rank"(%763, %750) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %765 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %766 = "cute.size"(%760) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %767 = "cute.get_scalars"(%766) : (!cute.int_tuple<"1">) -> i32
          %768 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %769 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%768, %767, %769) ({
          ^bb0(%arg21: i32):
            %874 = "cute.make_coord"(%arg21) : (i32) -> !cute.coord<"(_,?)">
            %875 = "cute.slice"(%760, %874) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %876 = "cute.crd2idx"(%874, %760) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %877 = "cute.add_offset"(%751, %876) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %878 = "cute.make_view"(%877, %875) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
            %879 = "cute.slice"(%761, %874) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %880 = "cute.crd2idx"(%874, %761) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %881 = "cute.add_offset"(%752, %880) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %882 = "cute.make_view"(%881, %879) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
            %883 = "cute.slice"(%765, %874) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %884 = "cute.crd2idx"(%874, %765) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %885 = "cute.add_offset"(%762, %884) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %886 = "cute.make_view"(%885, %883) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
            "cute.copy_atom_call"(%208, %878, %882, %886) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %770 = "cute.get_layout"(%271) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %771 = "cute.get_shape"(%770) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %772:5 = "cute.get_leaves"(%771) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %773 = "cute.get_layout"(%283) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %774 = "cute.get_shape"(%773) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %775:5 = "cute.get_leaves"(%774) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %776 = "cute.get_layout"(%271) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %777 = "cute.make_shape"() : () -> !cute.shape<"1">
          %778 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %779 = "cute.append_to_rank"(%776, %778) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %780 = "cute.make_view"(%272, %779) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %781 = "cute.get_iter"(%780) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %782 = "cute.get_layout"(%780) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %783 = "cute.get_shape"(%782) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %784:5 = "cute.get_leaves"(%783) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %785 = "cute.get_layout"(%780) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %786 = "cute.get_shape"(%785) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %787:5 = "cute.get_leaves"(%786) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %788 = "cute.get_iter"(%780) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %789 = "cute.get_layout"(%780) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %790 = "cute.get_scalars"(%789) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
          %791 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %792 = "cute.make_stride"(%790) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %793 = "cute.make_layout"(%791, %792) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %794 = "cute.make_view"(%788, %793) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
          %795 = "cute.get_iter"(%794) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %796 = "cute.get_iter"(%794) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %797 = "cute.get_layout"(%283) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %798 = "cute.make_shape"() : () -> !cute.shape<"1">
          %799 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %800 = "cute.append_to_rank"(%797, %799) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %801 = "cute.make_view"(%285, %800) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %802 = "cute.get_iter"(%801) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %803 = "cute.get_layout"(%801) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %804 = "cute.get_shape"(%803) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %805:5 = "cute.get_leaves"(%804) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %806 = "cute.get_layout"(%801) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %807 = "cute.get_shape"(%806) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %808:5 = "cute.get_leaves"(%807) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %809 = "cute.get_iter"(%801) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %810 = "cute.make_view"(%809) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
          %811 = "cute.get_iter"(%810) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %812 = "cute.get_iter"(%810) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %813 = "cute.get_layout"(%312) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %814 = "cute.make_shape"() : () -> !cute.shape<"1">
          %815 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %816 = "cute.append_to_rank"(%813, %815) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %817 = "cute.make_view"(%315, %816) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %818 = "cute.get_iter"(%817) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %819 = "cute.get_layout"(%817) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %820 = "cute.get_shape"(%819) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %821:5 = "cute.get_leaves"(%820) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %822 = "cute.get_layout"(%817) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %823 = "cute.get_shape"(%822) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %824:5 = "cute.get_leaves"(%823) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %825 = "cute.get_iter"(%817) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %826 = "cute.make_view"(%825) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
          %827 = "cute.get_iter"(%826) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %828 = "cute.get_iter"(%826) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %829 = "cute.get_layout"(%794) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %830 = "cute.get_shape"(%829) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %831:5 = "cute.get_leaves"(%830) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %832 = "cute.get_layout"(%810) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %833 = "cute.get_shape"(%832) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %834:5 = "cute.get_leaves"(%833) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %835 = "cute.get_layout"(%794) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %836 = "cute.size"(%835) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %837 = "cute.get_leaves"(%836) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %838 = "cute.get_layout"(%810) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %839 = "cute.size"(%838) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %840 = "cute.get_leaves"(%839) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %841 = "cute.static"() : () -> !cute.layout<"1:0">
          %842 = "cute.get_iter"(%794) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %843 = "cute.get_iter"(%810) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %844 = "cute.get_layout"(%794) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %845 = "cute.get_layout"(%810) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %846 = "cute.append_to_rank"(%844, %841) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %847 = "cute.append_to_rank"(%845, %841) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %848 = "cute.get_scalars"(%846) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
          %849 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %850 = "cute.make_stride"(%848) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %851 = "cute.make_layout"(%849, %850) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %852 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %853 = "cute.get_iter"(%826) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %854 = "cute.get_layout"(%826) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %855 = "cute.append_to_rank"(%854, %841) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %856 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %857 = "cute.size"(%851) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %858 = "cute.get_scalars"(%857) : (!cute.int_tuple<"1">) -> i32
          %859 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %860 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%859, %858, %860) ({
          ^bb0(%arg20: i32):
            %861 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,?)">
            %862 = "cute.slice"(%851, %861) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %863 = "cute.crd2idx"(%861, %851) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %864 = "cute.add_offset"(%842, %863) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %865 = "cute.make_view"(%864, %862) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
            %866 = "cute.slice"(%852, %861) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %867 = "cute.crd2idx"(%861, %852) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %868 = "cute.add_offset"(%843, %867) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %869 = "cute.make_view"(%868, %866) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
            %870 = "cute.slice"(%856, %861) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %871 = "cute.crd2idx"(%861, %856) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %872 = "cute.add_offset"(%853, %871) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %873 = "cute.make_view"(%872, %870) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
            "cute.copy_atom_call"(%208, %865, %869, %873) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.launch_dependents;", constraints = "", has_side_effects}> : () -> ()
        "scf.yield"() : () -> ()
      }, {
        %465 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %466 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %467 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%465, %466, %467) ({
        ^bb0(%arg17: i32):
          %572 = "cute.get_layout"(%271) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %573 = "cute.get_shape"(%572) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %574:5 = "cute.get_leaves"(%573) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %575 = "cute.get_layout"(%283) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %576 = "cute.get_shape"(%575) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %577:5 = "cute.get_leaves"(%576) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %578 = "cute.get_layout"(%271) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %579 = "cute.make_shape"() : () -> !cute.shape<"1">
          %580 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %581 = "cute.append_to_rank"(%578, %580) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %582 = "cute.make_view"(%272, %581) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %583 = "cute.get_iter"(%582) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %584 = "cute.get_layout"(%582) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %585 = "cute.get_shape"(%584) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %586:5 = "cute.get_leaves"(%585) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %587 = "cute.get_layout"(%582) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %588 = "cute.get_shape"(%587) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %589:5 = "cute.get_leaves"(%588) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %590 = "cute.get_iter"(%582) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %591 = "cute.get_layout"(%582) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %592 = "cute.get_scalars"(%591) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
          %593 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %594 = "cute.make_stride"(%592) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %595 = "cute.make_layout"(%593, %594) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %596 = "cute.make_view"(%590, %595) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
          %597 = "cute.get_iter"(%596) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %598 = "cute.get_iter"(%596) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %599 = "cute.get_layout"(%283) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %600 = "cute.make_shape"() : () -> !cute.shape<"1">
          %601 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %602 = "cute.append_to_rank"(%599, %601) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %603 = "cute.make_view"(%285, %602) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %604 = "cute.get_iter"(%603) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %605 = "cute.get_layout"(%603) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %606 = "cute.get_shape"(%605) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %607:5 = "cute.get_leaves"(%606) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %608 = "cute.get_layout"(%603) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %609 = "cute.get_shape"(%608) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %610:5 = "cute.get_leaves"(%609) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %611 = "cute.get_iter"(%603) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %612 = "cute.make_view"(%611) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
          %613 = "cute.get_iter"(%612) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %614 = "cute.get_iter"(%612) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %615 = "cute.get_layout"(%312) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %616 = "cute.make_shape"() : () -> !cute.shape<"1">
          %617 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %618 = "cute.append_to_rank"(%615, %617) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %619 = "cute.make_view"(%315, %618) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %620 = "cute.get_iter"(%619) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %621 = "cute.get_layout"(%619) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %622 = "cute.get_shape"(%621) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %623:5 = "cute.get_leaves"(%622) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %624 = "cute.get_layout"(%619) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %625 = "cute.get_shape"(%624) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %626:5 = "cute.get_leaves"(%625) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %627 = "cute.get_iter"(%619) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %628 = "cute.make_view"(%627) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
          %629 = "cute.get_iter"(%628) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %630 = "cute.get_iter"(%628) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %631 = "cute.get_layout"(%596) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %632 = "cute.get_shape"(%631) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %633:5 = "cute.get_leaves"(%632) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %634 = "cute.get_layout"(%612) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %635 = "cute.get_shape"(%634) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %636:5 = "cute.get_leaves"(%635) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %637 = "cute.get_layout"(%596) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %638 = "cute.size"(%637) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %639 = "cute.get_leaves"(%638) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %640 = "cute.get_layout"(%612) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %641 = "cute.size"(%640) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %642 = "cute.get_leaves"(%641) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %643 = "cute.static"() : () -> !cute.layout<"1:0">
          %644 = "cute.get_iter"(%596) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %645 = "cute.get_iter"(%612) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %646 = "cute.get_layout"(%596) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %647 = "cute.get_layout"(%612) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %648 = "cute.append_to_rank"(%646, %643) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %649 = "cute.append_to_rank"(%647, %643) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %650 = "cute.get_scalars"(%648) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
          %651 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %652 = "cute.make_stride"(%650) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %653 = "cute.make_layout"(%651, %652) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %654 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %655 = "cute.get_iter"(%628) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %656 = "cute.get_layout"(%628) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %657 = "cute.append_to_rank"(%656, %643) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %658 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %659 = "cute.size"(%653) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %660 = "cute.get_scalars"(%659) : (!cute.int_tuple<"1">) -> i32
          %661 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %662 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%661, %660, %662) ({
          ^bb0(%arg18: i32):
            %663 = "cute.make_coord"(%arg18) : (i32) -> !cute.coord<"(_,?)">
            %664 = "cute.slice"(%653, %663) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %665 = "cute.crd2idx"(%663, %653) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %666 = "cute.add_offset"(%644, %665) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %667 = "cute.make_view"(%666, %664) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
            %668 = "cute.slice"(%654, %663) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %669 = "cute.crd2idx"(%663, %654) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %670 = "cute.add_offset"(%645, %669) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %671 = "cute.make_view"(%670, %668) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
            %672 = "cute.slice"(%658, %663) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %673 = "cute.crd2idx"(%663, %658) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %674 = "cute.add_offset"(%655, %673) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %675 = "cute.make_view"(%674, %672) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
            "cute.copy_atom_call"(%208, %667, %671, %675) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.wait;", constraints = "", has_side_effects}> : () -> ()
        "scf.for"(%465, %466, %467) ({
        ^bb0(%arg15: i32):
          %468 = "cute.get_layout"(%268) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %469 = "cute.get_shape"(%468) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %470:5 = "cute.get_leaves"(%469) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %471 = "cute.get_layout"(%278) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %472 = "cute.get_shape"(%471) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %473:5 = "cute.get_leaves"(%472) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %474 = "cute.get_layout"(%268) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %475 = "cute.make_shape"() : () -> !cute.shape<"1">
          %476 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %477 = "cute.append_to_rank"(%474, %476) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %478 = "cute.make_view"(%269, %477) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %479 = "cute.get_iter"(%478) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %480 = "cute.get_layout"(%478) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %481 = "cute.get_shape"(%480) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %482:5 = "cute.get_leaves"(%481) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %483 = "cute.get_layout"(%478) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %484 = "cute.get_shape"(%483) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %485:5 = "cute.get_leaves"(%484) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %486 = "cute.get_iter"(%478) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %487 = "cute.get_layout"(%478) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %488 = "cute.get_scalars"(%487) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
          %489 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %490 = "cute.make_stride"(%488) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %491 = "cute.make_layout"(%489, %490) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %492 = "cute.make_view"(%486, %491) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
          %493 = "cute.get_iter"(%492) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %494 = "cute.get_iter"(%492) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %495 = "cute.get_layout"(%278) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %496 = "cute.make_shape"() : () -> !cute.shape<"1">
          %497 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %498 = "cute.append_to_rank"(%495, %497) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %499 = "cute.make_view"(%280, %498) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %500 = "cute.get_iter"(%499) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %501 = "cute.get_layout"(%499) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %502 = "cute.get_shape"(%501) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %503:5 = "cute.get_leaves"(%502) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %504 = "cute.get_layout"(%499) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %505 = "cute.get_shape"(%504) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %506:5 = "cute.get_leaves"(%505) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %507 = "cute.get_iter"(%499) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %508 = "cute.make_view"(%507) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
          %509 = "cute.get_iter"(%508) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %510 = "cute.get_iter"(%508) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %511 = "cute.get_layout"(%312) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %512 = "cute.make_shape"() : () -> !cute.shape<"1">
          %513 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
          %514 = "cute.append_to_rank"(%511, %513) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %515 = "cute.make_view"(%315, %514) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %516 = "cute.get_iter"(%515) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %517 = "cute.get_layout"(%515) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %518 = "cute.get_shape"(%517) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %519:5 = "cute.get_leaves"(%518) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %520 = "cute.get_layout"(%515) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %521 = "cute.get_shape"(%520) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %522:5 = "cute.get_leaves"(%521) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %523 = "cute.get_iter"(%515) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %524 = "cute.make_view"(%523) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
          %525 = "cute.get_iter"(%524) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %526 = "cute.get_iter"(%524) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %527 = "cute.get_layout"(%492) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %528 = "cute.get_shape"(%527) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %529:5 = "cute.get_leaves"(%528) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %530 = "cute.get_layout"(%508) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %531 = "cute.get_shape"(%530) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %532:5 = "cute.get_leaves"(%531) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %533 = "cute.get_layout"(%492) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %534 = "cute.size"(%533) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %535 = "cute.get_leaves"(%534) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %536 = "cute.get_layout"(%508) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %537 = "cute.size"(%536) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %538 = "cute.get_leaves"(%537) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %539 = "cute.static"() : () -> !cute.layout<"1:0">
          %540 = "cute.get_iter"(%492) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %541 = "cute.get_iter"(%508) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %542 = "cute.get_layout"(%492) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %543 = "cute.get_layout"(%508) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %544 = "cute.append_to_rank"(%542, %539) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %545 = "cute.append_to_rank"(%543, %539) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %546 = "cute.get_scalars"(%544) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
          %547 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %548 = "cute.make_stride"(%546) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %549 = "cute.make_layout"(%547, %548) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %550 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %551 = "cute.get_iter"(%524) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %552 = "cute.get_layout"(%524) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %553 = "cute.append_to_rank"(%552, %539) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %554 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %555 = "cute.size"(%549) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %556 = "cute.get_scalars"(%555) : (!cute.int_tuple<"1">) -> i32
          %557 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %558 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%557, %556, %558) ({
          ^bb0(%arg16: i32):
            %559 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,?)">
            %560 = "cute.slice"(%549, %559) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %561 = "cute.crd2idx"(%559, %549) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %562 = "cute.add_offset"(%540, %561) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %563 = "cute.make_view"(%562, %560) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
            %564 = "cute.slice"(%550, %559) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %565 = "cute.crd2idx"(%559, %550) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %566 = "cute.add_offset"(%541, %565) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %567 = "cute.make_view"(%566, %564) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
            %568 = "cute.slice"(%554, %559) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %569 = "cute.crd2idx"(%559, %554) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %570 = "cute.add_offset"(%551, %569) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %571 = "cute.make_view"(%570, %568) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
            "cute.copy_atom_call"(%208, %563, %567, %571) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %317 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %318:3 = "scf.for"(%309, %317, %311, %278, %283, %288) ({
      ^bb0(%arg11: i32, %arg12: !memref_rmem_f32_, %arg13: !memref_rmem_f32_, %arg14: !memref_rmem_f32_):
        %432 = "cute.get_iter"(%arg12) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %433 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %434 = "cute.get_iter"(%arg14) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %435 = "cute.get_iter"(%arg12) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %436 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %437 = "cute.get_iter"(%arg14) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %438 = "cute.get_layout"(%arg12) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %439 = "cute.get_shape"(%438) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %440:5 = "cute.get_leaves"(%439) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %441 = "cute.memref.load_vec"(%arg12) : (!memref_rmem_f32_) -> vector<16xf32>
        %442 = "cute.get_layout"(%arg12) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %443 = "cute.get_shape"(%442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %444:5 = "cute.get_leaves"(%443) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %445 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %446 = "cute.get_shape"(%445) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %447:5 = "cute.get_leaves"(%446) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %448 = "cute.memref.load_vec"(%arg13) : (!memref_rmem_f32_) -> vector<16xf32>
        %449 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %450 = "cute.get_shape"(%449) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %451:5 = "cute.get_leaves"(%450) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %452 = "arith.addf"(%441, %448) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
        %453 = "cute.get_layout"(%arg14) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %454 = "cute.get_shape"(%453) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %455:5 = "cute.get_leaves"(%454) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %456 = "cute.get_layout"(%arg14) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %457 = "cute.get_shape"(%456) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %458:5 = "cute.get_leaves"(%457) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %459 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %460 = "cute.size"(%459) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %461 = "cute.get_leaves"(%460) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        %462 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %463 = "cute.size"(%462) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %464 = "cute.get_leaves"(%463) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        "cute.memref.store_vec"(%452, %arg14) : (vector<16xf32>, !memref_rmem_f32_) -> ()
        "scf.yield"(%arg12, %arg13, %arg14) : (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> ()
      }) : (i32, i32, i32, !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)
      %319 = "cute.get_iter"(%318#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %320 = "cute.get_iter"(%318#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %321 = "cute.get_iter"(%318#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %322 = "cute.get_iter"(%318#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %323 = "cute.get_iter"(%318#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %324 = "cute.get_iter"(%318#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %325 = "cute.get_iter"(%318#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %326 = "cute.get_iter"(%318#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %327 = "cute.get_iter"(%318#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %328 = "cute.get_layout"(%318#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %329 = "cute.get_shape"(%328) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %330:5 = "cute.get_leaves"(%329) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %331 = "cute.get_layout"(%274) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %332 = "cute.get_shape"(%331) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %333:5 = "cute.get_leaves"(%332) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %334 = "cute.get_layout"(%318#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %335 = "cute.make_shape"() : () -> !cute.shape<"1">
      %336 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %337 = "cute.append_to_rank"(%334, %336) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %338 = "cute.make_view"(%327, %337) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %339 = "cute.get_iter"(%338) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %340 = "cute.get_layout"(%338) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %341 = "cute.get_shape"(%340) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %342:5 = "cute.get_leaves"(%341) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %343 = "cute.get_layout"(%338) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %344 = "cute.get_shape"(%343) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %345:5 = "cute.get_leaves"(%344) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %346 = "cute.get_iter"(%338) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %347 = "cute.make_view"(%346) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %348 = "cute.get_iter"(%347) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %349 = "cute.get_iter"(%347) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %350 = "cute.get_layout"(%274) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %351 = "cute.make_shape"() : () -> !cute.shape<"1">
      %352 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %353 = "cute.append_to_rank"(%350, %352) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %354 = "cute.make_view"(%275, %353) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %355 = "cute.get_iter"(%354) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %356 = "cute.get_layout"(%354) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %357 = "cute.get_shape"(%356) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %358:5 = "cute.get_leaves"(%357) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %359 = "cute.get_layout"(%354) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %360 = "cute.get_shape"(%359) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %361:5 = "cute.get_leaves"(%360) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %362 = "cute.get_iter"(%354) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %363 = "cute.get_layout"(%354) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %364 = "cute.get_scalars"(%363) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %365 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %366 = "cute.make_stride"(%364) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %367 = "cute.make_layout"(%365, %366) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %368 = "cute.make_view"(%362, %367) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %369 = "cute.get_iter"(%368) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %370 = "cute.get_iter"(%368) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %371 = "cute.get_layout"(%312) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %372 = "cute.make_shape"() : () -> !cute.shape<"1">
      %373 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %374 = "cute.append_to_rank"(%371, %373) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %375 = "cute.make_view"(%315, %374) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %376 = "cute.get_iter"(%375) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %377 = "cute.get_layout"(%375) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %378 = "cute.get_shape"(%377) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %379:5 = "cute.get_leaves"(%378) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %380 = "cute.get_layout"(%375) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %381 = "cute.get_shape"(%380) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %382:5 = "cute.get_leaves"(%381) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %383 = "cute.get_iter"(%375) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %384 = "cute.make_view"(%383) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %385 = "cute.get_iter"(%384) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %386 = "cute.get_iter"(%384) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %387 = "cute.get_layout"(%347) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %388 = "cute.get_shape"(%387) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %389:5 = "cute.get_leaves"(%388) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %390 = "cute.get_layout"(%368) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %391 = "cute.get_shape"(%390) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %392:5 = "cute.get_leaves"(%391) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %393 = "cute.get_layout"(%347) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %394 = "cute.size"(%393) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %395 = "cute.get_leaves"(%394) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %396 = "cute.get_layout"(%368) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %397 = "cute.size"(%396) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %398 = "cute.get_leaves"(%397) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %399 = "cute.static"() : () -> !cute.layout<"1:0">
      %400 = "cute.get_iter"(%347) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %401 = "cute.get_iter"(%368) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %402 = "cute.get_layout"(%347) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %403 = "cute.get_layout"(%368) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %404 = "cute.append_to_rank"(%402, %399) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %405 = "cute.append_to_rank"(%403, %399) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %406 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %407 = "cute.get_scalars"(%405) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %408 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %409 = "cute.make_stride"(%407) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %410 = "cute.make_layout"(%408, %409) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %411 = "cute.get_iter"(%384) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %412 = "cute.get_layout"(%384) : (!memref_rmem_i8_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %413 = "cute.append_to_rank"(%412, %399) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %414 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %415 = "cute.size"(%406) <{mode = array<i32: 1>}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %416 = "cute.get_scalars"(%415) : (!cute.int_tuple<"1">) -> i32
      %417 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %418 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%417, %416, %418) ({
      ^bb0(%arg10: i32):
        %419 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
        %420 = "cute.slice"(%406, %419) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %421 = "cute.crd2idx"(%419, %406) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %422 = "cute.add_offset"(%400, %421) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %423 = "cute.make_view"(%422, %420) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %424 = "cute.slice"(%410, %419) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %425 = "cute.crd2idx"(%419, %410) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %426 = "cute.add_offset"(%401, %425) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %427 = "cute.make_view"(%426, %424) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %428 = "cute.slice"(%414, %419) : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %429 = "cute.crd2idx"(%419, %414) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %430 = "cute.add_offset"(%411, %429) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %431 = "cute.make_view"(%430, %428) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        "cute.copy_atom_call"(%209, %423, %427, %431) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_2, !memref_gmem_f32_4, !memref_rmem_i8_2) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_5, !memref_gmem_f32_5, !memref_gmem_f32_5, !cuda.stream) -> i32, sym_name = "cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False"}> ({
  ^bb0(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5, %arg3: !cuda.stream):
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
    %128 = "arith.extsi"(%127) : (i32) -> i64
    %129 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %130 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %131 = "cuda.launch_cfg.create"(%129, %130, %130, %128, %120, %130, %130, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %132 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%131, %132) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %133 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%131, %133) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %134 = "cuda.launch_ex"(%131, %43, %60, %77, %103, %114, %116) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %135 = "cuda.cast"(%134) : (!cuda.result) -> i32
    "cuda.return_if_error"(%135) : (i32) -> ()
    %136 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%136) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
