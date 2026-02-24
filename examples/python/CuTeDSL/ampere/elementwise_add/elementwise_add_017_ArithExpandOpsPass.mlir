!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %207 = "cute.static"() : () -> !cute.int_tuple<"15">
      %208 = "cute.static"() : () -> !cute.int_tuple<"14">
      %209 = "cute.static"() : () -> !cute.int_tuple<"13">
      %210 = "cute.static"() : () -> !cute.int_tuple<"12">
      %211 = "cute.static"() : () -> !cute.int_tuple<"11">
      %212 = "cute.static"() : () -> !cute.int_tuple<"10">
      %213 = "cute.static"() : () -> !cute.int_tuple<"9">
      %214 = "cute.static"() : () -> !cute.int_tuple<"8">
      %215 = "arith.constant"() <{value = 3 : i64}> : () -> i64
      %216 = "cute.static"() : () -> !cute.int_tuple<"7">
      %217 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %218 = "cute.static"() : () -> !cute.int_tuple<"6">
      %219 = "arith.constant"() <{value = 1 : i64}> : () -> i64
      %220 = "cute.static"() : () -> !cute.int_tuple<"5">
      %221 = "cute.static"() : () -> !cute.int_tuple<"4">
      %222 = "cute.static"() : () -> !cute.int_tuple<"3">
      %223 = "cute.static"() : () -> !cute.int_tuple<"2">
      %224 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %225 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
      %226 = "cute.static"() : () -> !cute.int_tuple<"1">
      %227 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %228 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %229 = "cute.static"() : () -> !cute.layout<"1:0">
      %230 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %231 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %232 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %233 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %234 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %235 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %236 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %237 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %238 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %239 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %240 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %241 = "cute.make_coord"(%240) : (i32) -> !cute.coord<"((_,_),?)">
      %242 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %243:4 = "cute.get_scalars"(%242) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %244 = "cute.make_stride"(%243#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %245 = "cute.make_layout"(%238, %244) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %246 = "cute.crd2idx"(%241, %242) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %247 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %248 = "cute.add_offset"(%247, %246) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %249 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %250:4 = "cute.get_scalars"(%249) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %251 = "cute.make_stride"(%250#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %252 = "cute.make_layout"(%238, %251) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %253 = "cute.crd2idx"(%241, %249) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %254 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %255 = "cute.add_offset"(%254, %253) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %256 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %257:4 = "cute.get_scalars"(%256) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %258 = "cute.make_stride"(%257#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %259 = "cute.make_layout"(%238, %258) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %260 = "cute.crd2idx"(%241, %256) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %261 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %262 = "cute.add_offset"(%261, %260) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %263 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %264 = "cute.crd2idx"(%241, %263) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %265 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %266 = "cute.add_offset"(%265, %264) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %267 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %268 = "cute.make_tiled_copy"(%267) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %269 = "cute.make_tiled_copy"(%267) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %270 = "cute.make_tiled_copy"(%267) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %271 = "cute.get_scalars"(%245) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %272 = "arith.muli"(%271, %237) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %273 = "arith.divsi"(%239, %236) : (i32, i32) -> i32
      %274 = "arith.remsi"(%239, %236) : (i32, i32) -> i32
      %275 = "arith.muli"(%274, %235) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %276 = "arith.extsi"(%273) : (i32) -> i64
      %277 = "arith.muli"(%276, %272) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %278 = "arith.extsi"(%275) : (i32) -> i64
      %279 = "arith.addi"(%278, %277) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %280 = "cute.assume"(%279) : (i64) -> !cute.i64<divby 4>
      %281 = "cute.make_int_tuple"(%280) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %282 = "cute.add_offset"(%248, %281) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %283 = "cute.make_stride"(%271) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %284 = "cute.make_layout"(%234, %283) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %285 = "cute.get_scalars"(%252) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %286 = "arith.muli"(%285, %237) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %287 = "arith.muli"(%276, %286) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %288 = "arith.addi"(%278, %287) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %289 = "cute.assume"(%288) : (i64) -> !cute.i64<divby 4>
      %290 = "cute.make_int_tuple"(%289) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %291 = "cute.add_offset"(%255, %290) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %292 = "cute.make_stride"(%285) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %293 = "cute.make_layout"(%234, %292) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %294 = "cute.get_scalars"(%259) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %295 = "arith.muli"(%294, %237) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %296 = "arith.muli"(%276, %295) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %297 = "arith.addi"(%278, %296) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %298 = "cute.assume"(%297) : (i64) -> !cute.i64<divby 4>
      %299 = "cute.make_int_tuple"(%298) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %300 = "cute.add_offset"(%262, %299) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %301 = "cute.make_stride"(%294) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %302 = "cute.make_layout"(%234, %301) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %303 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %304 = "cute.get_iter"(%303) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %305 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %306 = "cute.get_iter"(%305) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %307 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %308 = "cute.get_iter"(%307) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %309 = "arith.muli"(%273, %235) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %310 = "cute.assume"(%309) : (i32) -> !cute.i32<divby 4>
      %311 = "cute.assume"(%275) : (i32) -> !cute.i32<divby 4>
      %312 = "cute.make_int_tuple"(%310, %311) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %313 = "cute.add_offset"(%266, %312) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %314 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %315 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
      %316:2 = "cute.get_scalars"(%315) : (!cute.coord<"(?,?)">) -> (i32, i32)
      "cf.br"(%233)[^bb1] : (i32) -> ()
    ^bb1(%317: i32):  // 2 preds: ^bb0, ^bb2
      %318 = "arith.cmpi"(%317, %232) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%318)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb2:  // pred: ^bb1
      %319 = "cute.make_coord"(%317) : (i32) -> !cute.coord<"?">
      %320 = "cute.crd2idx"(%319, %230) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
      %321 = "cute.add_offset"(%313, %320) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %322 = "cute.deref_arith_tuple_iter"(%321) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %323:2 = "cute.get_leaves"(%322) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %324 = "cute.make_coord"(%323#0, %323#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %325:2 = "cute.get_scalars"(%324) : (!cute.coord<"(?,?)">) -> (i32, i32)
      %326 = "arith.cmpi"(%325#0, %316#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %327 = "arith.cmpi"(%325#1, %316#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %328 = "arith.andi"(%326, %327) : (i1, i1) -> i1
      %329 = "arith.extui"(%328) : (i1) -> i8
      "cute.memref.store"(%314, %319, %329) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      %330 = "arith.addi"(%317, %231) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%330)[^bb1] : (i32) -> ()
    ^bb3:  // pred: ^bb1
      %331 = "cute.get_iter"(%314) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %332 = "cute.append_to_rank"(%284, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %333 = "cute.get_scalars"(%332) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %334 = "cute.make_stride"(%333) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %335 = "cute.make_layout"(%228, %334) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %336 = "cute.append_to_rank"(%335, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %337 = "cute.get_scalars"(%336) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %338 = "cute.make_stride"(%337) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %339 = "cute.make_layout"(%227, %338) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %340 = "cute.get_scalars"(%339) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %341 = "cute.make_stride"(%340) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %342 = "cute.make_layout"(%225, %341) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %343 = "cute.get_scalars"(%342) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %344 = "builtin.unrealized_conversion_cast"(%331) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %345 = "llvm.load"(%344) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %346 = "llvm.icmp"(%345, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%346)[^bb4, ^bb5] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb4:  // pred: ^bb3
      %347 = "builtin.unrealized_conversion_cast"(%282) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %348 = "builtin.unrealized_conversion_cast"(%304) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %349 = "llvm.load"(%347) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%349, %348) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb5] : () -> ()
    ^bb5:  // 2 preds: ^bb3, ^bb4
      %350 = "cute.add_offset"(%331, %226) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %351 = "builtin.unrealized_conversion_cast"(%350) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %352 = "llvm.load"(%351) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %353 = "llvm.icmp"(%352, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%353)[^bb6, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb6:  // pred: ^bb5
      %354 = "cute.add_offset"(%282, %226) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %355 = "cute.add_offset"(%304, %226) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %356 = "builtin.unrealized_conversion_cast"(%354) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %357 = "builtin.unrealized_conversion_cast"(%355) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %358 = "llvm.load"(%356) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%358, %357) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb7] : () -> ()
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %359 = "cute.add_offset"(%331, %223) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %360 = "builtin.unrealized_conversion_cast"(%359) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %361 = "llvm.load"(%360) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %362 = "llvm.icmp"(%361, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%362)[^bb8, ^bb9] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb8:  // pred: ^bb7
      %363 = "cute.add_offset"(%282, %223) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %364 = "cute.add_offset"(%304, %223) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %365 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %366 = "builtin.unrealized_conversion_cast"(%364) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %367 = "llvm.load"(%365) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%367, %366) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb9] : () -> ()
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %368 = "cute.add_offset"(%331, %222) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %369 = "builtin.unrealized_conversion_cast"(%368) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %370 = "llvm.load"(%369) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %371 = "llvm.icmp"(%370, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%371)[^bb10, ^bb11] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb10:  // pred: ^bb9
      %372 = "cute.add_offset"(%282, %222) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %373 = "cute.add_offset"(%304, %222) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %374 = "builtin.unrealized_conversion_cast"(%372) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %375 = "builtin.unrealized_conversion_cast"(%373) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %376 = "llvm.load"(%374) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%376, %375) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb11] : () -> ()
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %377 = "cute.add_offset"(%331, %221) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %378 = "builtin.unrealized_conversion_cast"(%377) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %379 = "llvm.load"(%378) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %380 = "llvm.icmp"(%379, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%380)[^bb12, ^bb13] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb12:  // pred: ^bb11
      %381 = "cute.make_int_tuple"(%343) : (i64) -> !cute.int_tuple<"?{i64}">
      %382 = "cute.add_offset"(%282, %381) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %383 = "cute.add_offset"(%304, %221) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %384 = "builtin.unrealized_conversion_cast"(%382) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %385 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %386 = "llvm.load"(%384) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%386, %385) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb13] : () -> ()
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %387 = "cute.add_offset"(%331, %220) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %388 = "builtin.unrealized_conversion_cast"(%387) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %389 = "llvm.load"(%388) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %390 = "llvm.icmp"(%389, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%390)[^bb14, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb14:  // pred: ^bb13
      %391 = "arith.addi"(%343, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %392 = "cute.make_int_tuple"(%391) : (i64) -> !cute.int_tuple<"?{i64}">
      %393 = "cute.add_offset"(%282, %392) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %394 = "cute.add_offset"(%304, %220) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %395 = "builtin.unrealized_conversion_cast"(%393) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %396 = "builtin.unrealized_conversion_cast"(%394) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %397 = "llvm.load"(%395) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%397, %396) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb15] : () -> ()
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %398 = "cute.add_offset"(%331, %218) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %399 = "builtin.unrealized_conversion_cast"(%398) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %400 = "llvm.load"(%399) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %401 = "llvm.icmp"(%400, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%401)[^bb16, ^bb17] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb16:  // pred: ^bb15
      %402 = "arith.addi"(%343, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %403 = "cute.make_int_tuple"(%402) : (i64) -> !cute.int_tuple<"?{i64}">
      %404 = "cute.add_offset"(%282, %403) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %405 = "cute.add_offset"(%304, %218) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %406 = "builtin.unrealized_conversion_cast"(%404) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %407 = "builtin.unrealized_conversion_cast"(%405) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %408 = "llvm.load"(%406) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%408, %407) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb17] : () -> ()
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %409 = "cute.add_offset"(%331, %216) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %410 = "builtin.unrealized_conversion_cast"(%409) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %411 = "llvm.load"(%410) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %412 = "llvm.icmp"(%411, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%412)[^bb18, ^bb19] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb18:  // pred: ^bb17
      %413 = "arith.addi"(%343, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %414 = "cute.make_int_tuple"(%413) : (i64) -> !cute.int_tuple<"?{i64}">
      %415 = "cute.add_offset"(%282, %414) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %416 = "cute.add_offset"(%304, %216) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %417 = "builtin.unrealized_conversion_cast"(%415) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %418 = "builtin.unrealized_conversion_cast"(%416) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %419 = "llvm.load"(%417) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%419, %418) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb19] : () -> ()
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %420 = "cute.add_offset"(%331, %214) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %421 = "builtin.unrealized_conversion_cast"(%420) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %422 = "llvm.load"(%421) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %423 = "llvm.icmp"(%422, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%423)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %424 = "arith.muli"(%343, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %425 = "cute.assume"(%424) : (i64) -> !cute.i64<divby 2>
      %426 = "cute.make_int_tuple"(%425) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %427 = "cute.add_offset"(%282, %426) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %428 = "cute.add_offset"(%304, %214) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %429 = "builtin.unrealized_conversion_cast"(%427) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %430 = "builtin.unrealized_conversion_cast"(%428) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %431 = "llvm.load"(%429) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%431, %430) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb21] : () -> ()
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %432 = "cute.add_offset"(%331, %213) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %433 = "builtin.unrealized_conversion_cast"(%432) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %434 = "llvm.load"(%433) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %435 = "llvm.icmp"(%434, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%435)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %436 = "arith.muli"(%343, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %437 = "arith.addi"(%436, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %438 = "cute.make_int_tuple"(%437) : (i64) -> !cute.int_tuple<"?{i64}">
      %439 = "cute.add_offset"(%282, %438) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %440 = "cute.add_offset"(%304, %213) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %441 = "builtin.unrealized_conversion_cast"(%439) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %442 = "builtin.unrealized_conversion_cast"(%440) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %443 = "llvm.load"(%441) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%443, %442) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %444 = "cute.add_offset"(%331, %212) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %445 = "builtin.unrealized_conversion_cast"(%444) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %446 = "llvm.load"(%445) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %447 = "llvm.icmp"(%446, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%447)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %448 = "arith.muli"(%343, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %449 = "arith.addi"(%448, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %450 = "cute.assume"(%449) : (i64) -> !cute.i64<divby 2>
      %451 = "cute.make_int_tuple"(%450) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %452 = "cute.add_offset"(%282, %451) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %453 = "cute.add_offset"(%304, %212) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %454 = "builtin.unrealized_conversion_cast"(%452) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %455 = "builtin.unrealized_conversion_cast"(%453) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %456 = "llvm.load"(%454) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%456, %455) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb25] : () -> ()
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %457 = "cute.add_offset"(%331, %211) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %458 = "builtin.unrealized_conversion_cast"(%457) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %459 = "llvm.load"(%458) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %460 = "llvm.icmp"(%459, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%460)[^bb26, ^bb27] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb26:  // pred: ^bb25
      %461 = "arith.muli"(%343, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %462 = "arith.addi"(%461, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %463 = "cute.make_int_tuple"(%462) : (i64) -> !cute.int_tuple<"?{i64}">
      %464 = "cute.add_offset"(%282, %463) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %465 = "cute.add_offset"(%304, %211) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %466 = "builtin.unrealized_conversion_cast"(%464) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %467 = "builtin.unrealized_conversion_cast"(%465) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %468 = "llvm.load"(%466) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%468, %467) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb27] : () -> ()
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %469 = "cute.add_offset"(%331, %210) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %470 = "builtin.unrealized_conversion_cast"(%469) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %471 = "llvm.load"(%470) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %472 = "llvm.icmp"(%471, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%472)[^bb28, ^bb29] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb28:  // pred: ^bb27
      %473 = "arith.muli"(%343, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %474 = "cute.assume"(%473) : (i64) -> !cute.i64<divby 3>
      %475 = "cute.make_int_tuple"(%474) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %476 = "cute.add_offset"(%282, %475) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %477 = "cute.add_offset"(%304, %210) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %478 = "builtin.unrealized_conversion_cast"(%476) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %479 = "builtin.unrealized_conversion_cast"(%477) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %480 = "llvm.load"(%478) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%480, %479) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb29] : () -> ()
    ^bb29:  // 2 preds: ^bb27, ^bb28
      %481 = "cute.add_offset"(%331, %209) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %482 = "builtin.unrealized_conversion_cast"(%481) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %483 = "llvm.load"(%482) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %484 = "llvm.icmp"(%483, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%484)[^bb30, ^bb31] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb30:  // pred: ^bb29
      %485 = "arith.muli"(%343, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %486 = "arith.addi"(%485, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %487 = "cute.make_int_tuple"(%486) : (i64) -> !cute.int_tuple<"?{i64}">
      %488 = "cute.add_offset"(%282, %487) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %489 = "cute.add_offset"(%304, %209) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %490 = "builtin.unrealized_conversion_cast"(%488) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %491 = "builtin.unrealized_conversion_cast"(%489) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %492 = "llvm.load"(%490) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%492, %491) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb31] : () -> ()
    ^bb31:  // 2 preds: ^bb29, ^bb30
      %493 = "cute.add_offset"(%331, %208) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %494 = "builtin.unrealized_conversion_cast"(%493) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %495 = "llvm.load"(%494) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %496 = "llvm.icmp"(%495, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%496)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %497 = "arith.muli"(%343, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %498 = "arith.addi"(%497, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %499 = "cute.make_int_tuple"(%498) : (i64) -> !cute.int_tuple<"?{i64}">
      %500 = "cute.add_offset"(%282, %499) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %501 = "cute.add_offset"(%304, %208) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %502 = "builtin.unrealized_conversion_cast"(%500) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %503 = "builtin.unrealized_conversion_cast"(%501) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %504 = "llvm.load"(%502) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%504, %503) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %505 = "cute.add_offset"(%331, %207) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %506 = "builtin.unrealized_conversion_cast"(%505) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %507 = "llvm.load"(%506) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %508 = "llvm.icmp"(%507, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%508)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %509 = "arith.muli"(%343, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %510 = "arith.addi"(%509, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %511 = "cute.assume"(%510) : (i64) -> !cute.i64<divby 3>
      %512 = "cute.make_int_tuple"(%511) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %513 = "cute.add_offset"(%282, %512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %514 = "cute.add_offset"(%304, %207) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %515 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %516 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %517 = "llvm.load"(%515) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%517, %516) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %518 = "cute.append_to_rank"(%293, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %519 = "cute.get_scalars"(%518) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %520 = "cute.make_stride"(%519) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %521 = "cute.make_layout"(%228, %520) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %522 = "cute.append_to_rank"(%521, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %523 = "cute.get_scalars"(%522) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %524 = "cute.make_stride"(%523) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %525 = "cute.make_layout"(%227, %524) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %526 = "cute.get_scalars"(%525) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %527 = "cute.make_stride"(%526) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %528 = "cute.make_layout"(%225, %527) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %529 = "cute.get_scalars"(%528) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %530 = "llvm.load"(%344) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %531 = "llvm.icmp"(%530, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%531)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %532 = "builtin.unrealized_conversion_cast"(%291) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %533 = "builtin.unrealized_conversion_cast"(%306) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %534 = "llvm.load"(%532) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%534, %533) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %535 = "llvm.load"(%351) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %536 = "llvm.icmp"(%535, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%536)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %537 = "cute.add_offset"(%291, %226) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %538 = "cute.add_offset"(%306, %226) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %539 = "builtin.unrealized_conversion_cast"(%537) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %540 = "builtin.unrealized_conversion_cast"(%538) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %541 = "llvm.load"(%539) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%541, %540) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %542 = "llvm.load"(%360) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %543 = "llvm.icmp"(%542, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%543)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %544 = "cute.add_offset"(%291, %223) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %545 = "cute.add_offset"(%306, %223) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %546 = "builtin.unrealized_conversion_cast"(%544) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %547 = "builtin.unrealized_conversion_cast"(%545) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %548 = "llvm.load"(%546) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%548, %547) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %549 = "llvm.load"(%369) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %550 = "llvm.icmp"(%549, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%550)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %551 = "cute.add_offset"(%291, %222) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %552 = "cute.add_offset"(%306, %222) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %553 = "builtin.unrealized_conversion_cast"(%551) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %554 = "builtin.unrealized_conversion_cast"(%552) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %555 = "llvm.load"(%553) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%555, %554) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %556 = "llvm.load"(%378) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %557 = "llvm.icmp"(%556, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%557)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %558 = "cute.make_int_tuple"(%529) : (i64) -> !cute.int_tuple<"?{i64}">
      %559 = "cute.add_offset"(%291, %558) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %560 = "cute.add_offset"(%306, %221) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %561 = "builtin.unrealized_conversion_cast"(%559) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %562 = "builtin.unrealized_conversion_cast"(%560) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %563 = "llvm.load"(%561) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%563, %562) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %564 = "llvm.load"(%388) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %565 = "llvm.icmp"(%564, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%565)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %566 = "arith.addi"(%529, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %567 = "cute.make_int_tuple"(%566) : (i64) -> !cute.int_tuple<"?{i64}">
      %568 = "cute.add_offset"(%291, %567) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %569 = "cute.add_offset"(%306, %220) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %570 = "builtin.unrealized_conversion_cast"(%568) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %571 = "builtin.unrealized_conversion_cast"(%569) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %572 = "llvm.load"(%570) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%572, %571) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb47] : () -> ()
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %573 = "llvm.load"(%399) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %574 = "llvm.icmp"(%573, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%574)[^bb48, ^bb49] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb48:  // pred: ^bb47
      %575 = "arith.addi"(%529, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %576 = "cute.make_int_tuple"(%575) : (i64) -> !cute.int_tuple<"?{i64}">
      %577 = "cute.add_offset"(%291, %576) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %578 = "cute.add_offset"(%306, %218) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %579 = "builtin.unrealized_conversion_cast"(%577) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %580 = "builtin.unrealized_conversion_cast"(%578) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %581 = "llvm.load"(%579) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%581, %580) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb49] : () -> ()
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %582 = "llvm.load"(%410) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %583 = "llvm.icmp"(%582, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%583)[^bb50, ^bb51] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb50:  // pred: ^bb49
      %584 = "arith.addi"(%529, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %585 = "cute.make_int_tuple"(%584) : (i64) -> !cute.int_tuple<"?{i64}">
      %586 = "cute.add_offset"(%291, %585) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %587 = "cute.add_offset"(%306, %216) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %588 = "builtin.unrealized_conversion_cast"(%586) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %589 = "builtin.unrealized_conversion_cast"(%587) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %590 = "llvm.load"(%588) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%590, %589) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb51] : () -> ()
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %591 = "llvm.load"(%421) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %592 = "llvm.icmp"(%591, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%592)[^bb52, ^bb53] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb52:  // pred: ^bb51
      %593 = "arith.muli"(%529, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %594 = "cute.assume"(%593) : (i64) -> !cute.i64<divby 2>
      %595 = "cute.make_int_tuple"(%594) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %596 = "cute.add_offset"(%291, %595) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %597 = "cute.add_offset"(%306, %214) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %598 = "builtin.unrealized_conversion_cast"(%596) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %599 = "builtin.unrealized_conversion_cast"(%597) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %600 = "llvm.load"(%598) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%600, %599) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb53] : () -> ()
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %601 = "llvm.load"(%433) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %602 = "llvm.icmp"(%601, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%602)[^bb54, ^bb55] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb54:  // pred: ^bb53
      %603 = "arith.muli"(%529, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %604 = "arith.addi"(%603, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %605 = "cute.make_int_tuple"(%604) : (i64) -> !cute.int_tuple<"?{i64}">
      %606 = "cute.add_offset"(%291, %605) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %607 = "cute.add_offset"(%306, %213) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %608 = "builtin.unrealized_conversion_cast"(%606) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %609 = "builtin.unrealized_conversion_cast"(%607) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %610 = "llvm.load"(%608) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%610, %609) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb55] : () -> ()
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %611 = "llvm.load"(%445) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %612 = "llvm.icmp"(%611, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%612)[^bb56, ^bb57] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb56:  // pred: ^bb55
      %613 = "arith.muli"(%529, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %614 = "arith.addi"(%613, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %615 = "cute.assume"(%614) : (i64) -> !cute.i64<divby 2>
      %616 = "cute.make_int_tuple"(%615) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %617 = "cute.add_offset"(%291, %616) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %618 = "cute.add_offset"(%306, %212) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %619 = "builtin.unrealized_conversion_cast"(%617) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %620 = "builtin.unrealized_conversion_cast"(%618) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %621 = "llvm.load"(%619) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%621, %620) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb57] : () -> ()
    ^bb57:  // 2 preds: ^bb55, ^bb56
      %622 = "llvm.load"(%458) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %623 = "llvm.icmp"(%622, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%623)[^bb58, ^bb59] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb58:  // pred: ^bb57
      %624 = "arith.muli"(%529, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %625 = "arith.addi"(%624, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %626 = "cute.make_int_tuple"(%625) : (i64) -> !cute.int_tuple<"?{i64}">
      %627 = "cute.add_offset"(%291, %626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %628 = "cute.add_offset"(%306, %211) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %629 = "builtin.unrealized_conversion_cast"(%627) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %630 = "builtin.unrealized_conversion_cast"(%628) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %631 = "llvm.load"(%629) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%631, %630) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb59] : () -> ()
    ^bb59:  // 2 preds: ^bb57, ^bb58
      %632 = "llvm.load"(%470) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %633 = "llvm.icmp"(%632, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%633)[^bb60, ^bb61] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb60:  // pred: ^bb59
      %634 = "arith.muli"(%529, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %635 = "cute.assume"(%634) : (i64) -> !cute.i64<divby 3>
      %636 = "cute.make_int_tuple"(%635) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %637 = "cute.add_offset"(%291, %636) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %638 = "cute.add_offset"(%306, %210) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %639 = "builtin.unrealized_conversion_cast"(%637) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %640 = "builtin.unrealized_conversion_cast"(%638) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %641 = "llvm.load"(%639) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%641, %640) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb61] : () -> ()
    ^bb61:  // 2 preds: ^bb59, ^bb60
      %642 = "llvm.load"(%482) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %643 = "llvm.icmp"(%642, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%643)[^bb62, ^bb63] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb62:  // pred: ^bb61
      %644 = "arith.muli"(%529, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %645 = "arith.addi"(%644, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %646 = "cute.make_int_tuple"(%645) : (i64) -> !cute.int_tuple<"?{i64}">
      %647 = "cute.add_offset"(%291, %646) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %648 = "cute.add_offset"(%306, %209) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %649 = "builtin.unrealized_conversion_cast"(%647) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %650 = "builtin.unrealized_conversion_cast"(%648) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %651 = "llvm.load"(%649) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%651, %650) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb63] : () -> ()
    ^bb63:  // 2 preds: ^bb61, ^bb62
      %652 = "llvm.load"(%494) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %653 = "llvm.icmp"(%652, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%653)[^bb64, ^bb65] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb64:  // pred: ^bb63
      %654 = "arith.muli"(%529, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %655 = "arith.addi"(%654, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %656 = "cute.make_int_tuple"(%655) : (i64) -> !cute.int_tuple<"?{i64}">
      %657 = "cute.add_offset"(%291, %656) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %658 = "cute.add_offset"(%306, %208) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %659 = "builtin.unrealized_conversion_cast"(%657) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %660 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %661 = "llvm.load"(%659) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%661, %660) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb65] : () -> ()
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %662 = "llvm.load"(%506) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %663 = "llvm.icmp"(%662, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%663)[^bb66, ^bb67] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb66:  // pred: ^bb65
      %664 = "arith.muli"(%529, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %665 = "arith.addi"(%664, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %666 = "cute.assume"(%665) : (i64) -> !cute.i64<divby 3>
      %667 = "cute.make_int_tuple"(%666) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %668 = "cute.add_offset"(%291, %667) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %669 = "cute.add_offset"(%306, %207) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %670 = "builtin.unrealized_conversion_cast"(%668) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %671 = "builtin.unrealized_conversion_cast"(%669) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %672 = "llvm.load"(%670) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%672, %671) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb67] : () -> ()
    ^bb67:  // 2 preds: ^bb65, ^bb66
      %673 = "cute.memref.load_vec"(%303) : (!memref_rmem_f32_) -> vector<16xf32>
      %674 = "cute.memref.load_vec"(%305) : (!memref_rmem_f32_) -> vector<16xf32>
      %675 = "arith.addf"(%673, %674) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%675, %307) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %676 = "cute.append_to_rank"(%302, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %677 = "cute.get_scalars"(%676) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %678 = "cute.make_stride"(%677) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %679 = "cute.make_layout"(%228, %678) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %680 = "cute.append_to_rank"(%679, %229) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %681 = "cute.get_scalars"(%680) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %682 = "cute.make_stride"(%681) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %683 = "cute.make_layout"(%227, %682) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %684 = "cute.get_scalars"(%683) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %685 = "cute.make_stride"(%684) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %686 = "cute.make_layout"(%225, %685) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %687 = "cute.get_scalars"(%686) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %688 = "llvm.load"(%344) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %689 = "llvm.icmp"(%688, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%689)[^bb68, ^bb69] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb68:  // pred: ^bb67
      %690 = "builtin.unrealized_conversion_cast"(%308) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %691 = "builtin.unrealized_conversion_cast"(%300) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %692 = "llvm.load"(%690) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%692, %691) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb69] : () -> ()
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %693 = "llvm.load"(%351) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %694 = "llvm.icmp"(%693, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%694)[^bb70, ^bb71] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb70:  // pred: ^bb69
      %695 = "cute.add_offset"(%308, %226) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %696 = "cute.add_offset"(%300, %226) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %697 = "builtin.unrealized_conversion_cast"(%695) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %698 = "builtin.unrealized_conversion_cast"(%696) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %699 = "llvm.load"(%697) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%699, %698) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb71] : () -> ()
    ^bb71:  // 2 preds: ^bb69, ^bb70
      %700 = "llvm.load"(%360) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %701 = "llvm.icmp"(%700, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%701)[^bb72, ^bb73] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb72:  // pred: ^bb71
      %702 = "cute.add_offset"(%308, %223) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %703 = "cute.add_offset"(%300, %223) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %704 = "builtin.unrealized_conversion_cast"(%702) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %705 = "builtin.unrealized_conversion_cast"(%703) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %706 = "llvm.load"(%704) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%706, %705) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb73] : () -> ()
    ^bb73:  // 2 preds: ^bb71, ^bb72
      %707 = "llvm.load"(%369) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %708 = "llvm.icmp"(%707, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%708)[^bb74, ^bb75] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb74:  // pred: ^bb73
      %709 = "cute.add_offset"(%308, %222) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %710 = "cute.add_offset"(%300, %222) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %711 = "builtin.unrealized_conversion_cast"(%709) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %712 = "builtin.unrealized_conversion_cast"(%710) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %713 = "llvm.load"(%711) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%713, %712) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb75] : () -> ()
    ^bb75:  // 2 preds: ^bb73, ^bb74
      %714 = "llvm.load"(%378) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %715 = "llvm.icmp"(%714, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%715)[^bb76, ^bb77] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb76:  // pred: ^bb75
      %716 = "cute.add_offset"(%308, %221) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %717 = "cute.make_int_tuple"(%687) : (i64) -> !cute.int_tuple<"?{i64}">
      %718 = "cute.add_offset"(%300, %717) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %719 = "builtin.unrealized_conversion_cast"(%716) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %720 = "builtin.unrealized_conversion_cast"(%718) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %721 = "llvm.load"(%719) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%721, %720) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb77] : () -> ()
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %722 = "llvm.load"(%388) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %723 = "llvm.icmp"(%722, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%723)[^bb78, ^bb79] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb78:  // pred: ^bb77
      %724 = "cute.add_offset"(%308, %220) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %725 = "arith.addi"(%687, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %726 = "cute.make_int_tuple"(%725) : (i64) -> !cute.int_tuple<"?{i64}">
      %727 = "cute.add_offset"(%300, %726) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %728 = "builtin.unrealized_conversion_cast"(%724) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %729 = "builtin.unrealized_conversion_cast"(%727) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %730 = "llvm.load"(%728) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%730, %729) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb79] : () -> ()
    ^bb79:  // 2 preds: ^bb77, ^bb78
      %731 = "llvm.load"(%399) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %732 = "llvm.icmp"(%731, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%732)[^bb80, ^bb81] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb80:  // pred: ^bb79
      %733 = "cute.add_offset"(%308, %218) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %734 = "arith.addi"(%687, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %735 = "cute.make_int_tuple"(%734) : (i64) -> !cute.int_tuple<"?{i64}">
      %736 = "cute.add_offset"(%300, %735) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %737 = "builtin.unrealized_conversion_cast"(%733) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %738 = "builtin.unrealized_conversion_cast"(%736) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %739 = "llvm.load"(%737) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%739, %738) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb81] : () -> ()
    ^bb81:  // 2 preds: ^bb79, ^bb80
      %740 = "llvm.load"(%410) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %741 = "llvm.icmp"(%740, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%741)[^bb82, ^bb83] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb82:  // pred: ^bb81
      %742 = "cute.add_offset"(%308, %216) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %743 = "arith.addi"(%687, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %744 = "cute.make_int_tuple"(%743) : (i64) -> !cute.int_tuple<"?{i64}">
      %745 = "cute.add_offset"(%300, %744) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %746 = "builtin.unrealized_conversion_cast"(%742) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %747 = "builtin.unrealized_conversion_cast"(%745) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %748 = "llvm.load"(%746) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%748, %747) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb83] : () -> ()
    ^bb83:  // 2 preds: ^bb81, ^bb82
      %749 = "llvm.load"(%421) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %750 = "llvm.icmp"(%749, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%750)[^bb84, ^bb85] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb84:  // pred: ^bb83
      %751 = "cute.add_offset"(%308, %214) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %752 = "arith.muli"(%687, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %753 = "cute.assume"(%752) : (i64) -> !cute.i64<divby 2>
      %754 = "cute.make_int_tuple"(%753) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %755 = "cute.add_offset"(%300, %754) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %756 = "builtin.unrealized_conversion_cast"(%751) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %757 = "builtin.unrealized_conversion_cast"(%755) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %758 = "llvm.load"(%756) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%758, %757) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb85] : () -> ()
    ^bb85:  // 2 preds: ^bb83, ^bb84
      %759 = "llvm.load"(%433) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %760 = "llvm.icmp"(%759, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%760)[^bb86, ^bb87] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb86:  // pred: ^bb85
      %761 = "cute.add_offset"(%308, %213) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %762 = "arith.muli"(%687, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %763 = "arith.addi"(%762, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %764 = "cute.make_int_tuple"(%763) : (i64) -> !cute.int_tuple<"?{i64}">
      %765 = "cute.add_offset"(%300, %764) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %766 = "builtin.unrealized_conversion_cast"(%761) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %767 = "builtin.unrealized_conversion_cast"(%765) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %768 = "llvm.load"(%766) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%768, %767) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb87] : () -> ()
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %769 = "llvm.load"(%445) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %770 = "llvm.icmp"(%769, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%770)[^bb88, ^bb89] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb88:  // pred: ^bb87
      %771 = "cute.add_offset"(%308, %212) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %772 = "arith.muli"(%687, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %773 = "arith.addi"(%772, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %774 = "cute.assume"(%773) : (i64) -> !cute.i64<divby 2>
      %775 = "cute.make_int_tuple"(%774) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %776 = "cute.add_offset"(%300, %775) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %777 = "builtin.unrealized_conversion_cast"(%771) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %778 = "builtin.unrealized_conversion_cast"(%776) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %779 = "llvm.load"(%777) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%779, %778) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb89] : () -> ()
    ^bb89:  // 2 preds: ^bb87, ^bb88
      %780 = "llvm.load"(%458) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %781 = "llvm.icmp"(%780, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%781)[^bb90, ^bb91] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb90:  // pred: ^bb89
      %782 = "cute.add_offset"(%308, %211) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %783 = "arith.muli"(%687, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %784 = "arith.addi"(%783, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %785 = "cute.make_int_tuple"(%784) : (i64) -> !cute.int_tuple<"?{i64}">
      %786 = "cute.add_offset"(%300, %785) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %787 = "builtin.unrealized_conversion_cast"(%782) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %788 = "builtin.unrealized_conversion_cast"(%786) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %789 = "llvm.load"(%787) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%789, %788) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb91] : () -> ()
    ^bb91:  // 2 preds: ^bb89, ^bb90
      %790 = "llvm.load"(%470) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %791 = "llvm.icmp"(%790, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%791)[^bb92, ^bb93] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb92:  // pred: ^bb91
      %792 = "cute.add_offset"(%308, %210) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %793 = "arith.muli"(%687, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %794 = "cute.assume"(%793) : (i64) -> !cute.i64<divby 3>
      %795 = "cute.make_int_tuple"(%794) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %796 = "cute.add_offset"(%300, %795) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %797 = "builtin.unrealized_conversion_cast"(%792) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %798 = "builtin.unrealized_conversion_cast"(%796) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %799 = "llvm.load"(%797) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%799, %798) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb93] : () -> ()
    ^bb93:  // 2 preds: ^bb91, ^bb92
      %800 = "llvm.load"(%482) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %801 = "llvm.icmp"(%800, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%801)[^bb94, ^bb95] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb94:  // pred: ^bb93
      %802 = "cute.add_offset"(%308, %209) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %803 = "arith.muli"(%687, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %804 = "arith.addi"(%803, %219) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %805 = "cute.make_int_tuple"(%804) : (i64) -> !cute.int_tuple<"?{i64}">
      %806 = "cute.add_offset"(%300, %805) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %807 = "builtin.unrealized_conversion_cast"(%802) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %808 = "builtin.unrealized_conversion_cast"(%806) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %809 = "llvm.load"(%807) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%809, %808) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb95] : () -> ()
    ^bb95:  // 2 preds: ^bb93, ^bb94
      %810 = "llvm.load"(%494) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %811 = "llvm.icmp"(%810, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%811)[^bb96, ^bb97] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb96:  // pred: ^bb95
      %812 = "cute.add_offset"(%308, %208) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %813 = "arith.muli"(%687, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %814 = "arith.addi"(%813, %217) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %815 = "cute.make_int_tuple"(%814) : (i64) -> !cute.int_tuple<"?{i64}">
      %816 = "cute.add_offset"(%300, %815) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %817 = "builtin.unrealized_conversion_cast"(%812) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %818 = "builtin.unrealized_conversion_cast"(%816) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %819 = "llvm.load"(%817) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%819, %818) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb97] : () -> ()
    ^bb97:  // 2 preds: ^bb95, ^bb96
      %820 = "llvm.load"(%506) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %821 = "llvm.icmp"(%820, %224) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%821)[^bb98, ^bb99] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb98:  // pred: ^bb97
      %822 = "cute.add_offset"(%308, %207) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %823 = "arith.muli"(%687, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %824 = "arith.addi"(%823, %215) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %825 = "cute.assume"(%824) : (i64) -> !cute.i64<divby 3>
      %826 = "cute.make_int_tuple"(%825) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %827 = "cute.add_offset"(%300, %826) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %828 = "builtin.unrealized_conversion_cast"(%822) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %829 = "builtin.unrealized_conversion_cast"(%827) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %830 = "llvm.load"(%828) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%830, %829) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb99] : () -> ()
    ^bb99:  // 2 preds: ^bb97, ^bb98
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_f32_1, !memref_gmem_f32_1) -> i32, sym_name = "cutlass_elementwise_add_tensor00644_03711_00110_04851_03515_08385_15093_00759_05930_07060_10713_18194_00944_06791_03214_06920_01900_16902_02636_10262_09792_12286_01389_04307_02417_"}> ({
  ^bb0(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %2 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %3 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %4 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
    %5 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %6 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %7 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %8 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %9 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %10:3 = "cute.get_scalars"(%9) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %11 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %12 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %13 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %14 = "arith.cmpi"(%7, %12) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %15 = "arith.select"(%14, %13, %11) : (i1, i32, i32) -> i32
    %16 = "arith.addi"(%15, %10#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %17 = "arith.divsi"(%16, %7) : (i32, i32) -> i32
    %18 = "arith.addi"(%11, %17) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %19 = "arith.subi"(%12, %10#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %20 = "arith.divsi"(%19, %7) : (i32, i32) -> i32
    %21 = "arith.subi"(%12, %20) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %22 = "arith.cmpi"(%10#0, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %23 = "arith.cmpi"(%10#0, %12) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %24 = "arith.cmpi"(%7, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %25 = "arith.cmpi"(%7, %12) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %26 = "arith.andi"(%22, %24) : (i1, i1) -> i1
    %27 = "arith.andi"(%23, %25) : (i1, i1) -> i1
    %28 = "arith.ori"(%26, %27) : (i1, i1) -> i1
    %29 = "arith.select"(%28, %18, %21) : (i1, i32, i32) -> i32
    %30 = "arith.muli"(%10#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %31 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %32 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %33 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %34 = "arith.cmpi"(%5, %32) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %35 = "arith.select"(%34, %33, %31) : (i1, i32, i32) -> i32
    %36 = "arith.addi"(%35, %10#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %37 = "arith.divsi"(%36, %5) : (i32, i32) -> i32
    %38 = "arith.addi"(%31, %37) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %39 = "arith.subi"(%32, %10#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %40 = "arith.divsi"(%39, %5) : (i32, i32) -> i32
    %41 = "arith.subi"(%32, %40) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %42 = "arith.cmpi"(%10#1, %32) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %43 = "arith.cmpi"(%10#1, %32) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %44 = "arith.cmpi"(%5, %32) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %45 = "arith.cmpi"(%5, %32) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %46 = "arith.andi"(%42, %44) : (i1, i1) -> i1
    %47 = "arith.andi"(%43, %45) : (i1, i1) -> i1
    %48 = "arith.ori"(%46, %47) : (i1, i1) -> i1
    %49 = "arith.select"(%48, %38, %41) : (i1, i32, i32) -> i32
    %50 = "cute.make_shape"(%29, %49) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %51 = "cute.assume"(%30) : (i64) -> !cute.i64<divby 16>
    %52 = "cute.make_stride"(%10#2, %51) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %53 = "cute.make_layout"(%50, %52) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %54 = "cute.make_view"(%8, %53) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %55 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %56 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %57:3 = "cute.get_scalars"(%56) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %58 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %59 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %60 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %61 = "arith.cmpi"(%7, %59) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %62 = "arith.select"(%61, %60, %58) : (i1, i32, i32) -> i32
    %63 = "arith.addi"(%62, %57#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %64 = "arith.divsi"(%63, %7) : (i32, i32) -> i32
    %65 = "arith.addi"(%58, %64) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %66 = "arith.subi"(%59, %57#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %67 = "arith.divsi"(%66, %7) : (i32, i32) -> i32
    %68 = "arith.subi"(%59, %67) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %69 = "arith.cmpi"(%57#0, %59) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %70 = "arith.cmpi"(%57#0, %59) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %71 = "arith.cmpi"(%7, %59) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %72 = "arith.cmpi"(%7, %59) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %73 = "arith.andi"(%69, %71) : (i1, i1) -> i1
    %74 = "arith.andi"(%70, %72) : (i1, i1) -> i1
    %75 = "arith.ori"(%73, %74) : (i1, i1) -> i1
    %76 = "arith.select"(%75, %65, %68) : (i1, i32, i32) -> i32
    %77 = "arith.muli"(%57#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %78 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %79 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %80 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %81 = "arith.cmpi"(%5, %79) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %82 = "arith.select"(%81, %80, %78) : (i1, i32, i32) -> i32
    %83 = "arith.addi"(%82, %57#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %84 = "arith.divsi"(%83, %5) : (i32, i32) -> i32
    %85 = "arith.addi"(%78, %84) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %86 = "arith.subi"(%79, %57#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %87 = "arith.divsi"(%86, %5) : (i32, i32) -> i32
    %88 = "arith.subi"(%79, %87) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %89 = "arith.cmpi"(%57#1, %79) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %90 = "arith.cmpi"(%57#1, %79) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %91 = "arith.cmpi"(%5, %79) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %92 = "arith.cmpi"(%5, %79) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %93 = "arith.andi"(%89, %91) : (i1, i1) -> i1
    %94 = "arith.andi"(%90, %92) : (i1, i1) -> i1
    %95 = "arith.ori"(%93, %94) : (i1, i1) -> i1
    %96 = "arith.select"(%95, %85, %88) : (i1, i32, i32) -> i32
    %97 = "cute.make_shape"(%76, %96) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %98 = "cute.assume"(%77) : (i64) -> !cute.i64<divby 16>
    %99 = "cute.make_stride"(%57#2, %98) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %100 = "cute.make_layout"(%97, %99) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %101 = "cute.make_view"(%55, %100) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %102 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %103 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %104:3 = "cute.get_scalars"(%103) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %105 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %106 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %107 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %108 = "arith.cmpi"(%7, %106) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %109 = "arith.select"(%108, %107, %105) : (i1, i32, i32) -> i32
    %110 = "arith.addi"(%109, %104#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %111 = "arith.divsi"(%110, %7) : (i32, i32) -> i32
    %112 = "arith.addi"(%105, %111) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %113 = "arith.subi"(%106, %104#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %114 = "arith.divsi"(%113, %7) : (i32, i32) -> i32
    %115 = "arith.subi"(%106, %114) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %116 = "arith.cmpi"(%104#0, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %117 = "arith.cmpi"(%104#0, %106) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %118 = "arith.cmpi"(%7, %106) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %119 = "arith.cmpi"(%7, %106) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %120 = "arith.andi"(%116, %118) : (i1, i1) -> i1
    %121 = "arith.andi"(%117, %119) : (i1, i1) -> i1
    %122 = "arith.ori"(%120, %121) : (i1, i1) -> i1
    %123 = "arith.select"(%122, %112, %115) : (i1, i32, i32) -> i32
    %124 = "arith.muli"(%104#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %125 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %126 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %127 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %128 = "arith.cmpi"(%5, %126) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %129 = "arith.select"(%128, %127, %125) : (i1, i32, i32) -> i32
    %130 = "arith.addi"(%129, %104#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %131 = "arith.divsi"(%130, %5) : (i32, i32) -> i32
    %132 = "arith.addi"(%125, %131) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %133 = "arith.subi"(%126, %104#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %134 = "arith.divsi"(%133, %5) : (i32, i32) -> i32
    %135 = "arith.subi"(%126, %134) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %136 = "arith.cmpi"(%104#1, %126) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %137 = "arith.cmpi"(%104#1, %126) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %138 = "arith.cmpi"(%5, %126) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %139 = "arith.cmpi"(%5, %126) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %140 = "arith.andi"(%136, %138) : (i1, i1) -> i1
    %141 = "arith.andi"(%137, %139) : (i1, i1) -> i1
    %142 = "arith.ori"(%140, %141) : (i1, i1) -> i1
    %143 = "arith.select"(%142, %132, %135) : (i1, i32, i32) -> i32
    %144 = "cute.make_shape"(%123, %143) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %145 = "cute.assume"(%124) : (i64) -> !cute.i64<divby 16>
    %146 = "cute.make_stride"(%104#2, %145) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %147 = "cute.make_layout"(%144, %146) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %148 = "cute.make_view"(%102, %147) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %149 = "cute.get_shape"(%103) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %150:2 = "cute.get_leaves"(%149) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %151 = "cute.to_int_tuple"(%150#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %152 = "cute.to_int_tuple"(%150#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %153 = "cute.make_shape"(%151, %152) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %154 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
    %155 = "cute.make_layout"(%153, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %156:2 = "cute.get_scalars"(%155) <{only_dynamic}> : (!cute.layout<"(?,?):(1@0,1@1)">) -> (i32, i32)
    %157 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %158 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %159 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %160 = "arith.cmpi"(%7, %158) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %161 = "arith.select"(%160, %159, %157) : (i1, i32, i32) -> i32
    %162 = "arith.addi"(%161, %156#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %163 = "arith.divsi"(%162, %7) : (i32, i32) -> i32
    %164 = "arith.addi"(%157, %163) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %165 = "arith.subi"(%158, %156#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %166 = "arith.divsi"(%165, %7) : (i32, i32) -> i32
    %167 = "arith.subi"(%158, %166) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %168 = "arith.cmpi"(%156#0, %158) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %169 = "arith.cmpi"(%156#0, %158) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %170 = "arith.cmpi"(%7, %158) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %171 = "arith.cmpi"(%7, %158) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %172 = "arith.andi"(%168, %170) : (i1, i1) -> i1
    %173 = "arith.andi"(%169, %171) : (i1, i1) -> i1
    %174 = "arith.ori"(%172, %173) : (i1, i1) -> i1
    %175 = "arith.select"(%174, %164, %167) : (i1, i32, i32) -> i32
    %176 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %177 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %178 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %179 = "arith.cmpi"(%5, %177) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %180 = "arith.select"(%179, %178, %176) : (i1, i32, i32) -> i32
    %181 = "arith.addi"(%180, %156#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %182 = "arith.divsi"(%181, %5) : (i32, i32) -> i32
    %183 = "arith.addi"(%176, %182) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %184 = "arith.subi"(%177, %156#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %185 = "arith.divsi"(%184, %5) : (i32, i32) -> i32
    %186 = "arith.subi"(%177, %185) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %187 = "arith.cmpi"(%156#1, %177) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %188 = "arith.cmpi"(%156#1, %177) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %189 = "arith.cmpi"(%5, %177) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %190 = "arith.cmpi"(%5, %177) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %191 = "arith.andi"(%187, %189) : (i1, i1) -> i1
    %192 = "arith.andi"(%188, %190) : (i1, i1) -> i1
    %193 = "arith.ori"(%191, %192) : (i1, i1) -> i1
    %194 = "arith.select"(%193, %183, %186) : (i1, i32, i32) -> i32
    %195 = "cute.make_shape"(%175, %194) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %196 = "cute.make_layout"(%195, %3) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %197 = "cute.make_view"(%154, %196) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %198 = "cute.get_scalars"(%151) : (!cute.int_tuple<"?">) -> i32
    %199 = "cute.get_scalars"(%152) : (!cute.int_tuple<"?">) -> i32
    %200 = "cute.size"(%147) <{mode = array<i32: 1>}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %201 = "cute.get_leaves"(%200) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %202 = "cute.get_scalars"(%201) : (!cute.int_tuple<"?">) -> i32
    %203 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %204 = "cuda.launch_cfg.create"(%5, %0, %0, %1, %202, %0, %0, %203) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%204, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%204, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %205 = "cuda.launch_ex"(%204, %54, %101, %148, %197, %198, %199) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %206 = "cuda.cast"(%205) : (!cuda.result) -> i32
    "cuda.return_if_error"(%206) : (i32) -> ()
    "func.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
