!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!mma_f16_f16_f32_128x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> (), sym_name = "kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0"}> ({
    ^bb0(%arg3: !mma_f16_f16_f32_128x256x16_, %arg4: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>, %arg5: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg6: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>, %arg7: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg8: !memref_gmem_f16_):
      %161 = "builtin.unrealized_conversion_cast"(%arg3) : (!mma_f16_f16_f32_128x256x16_) -> !llvm.struct<(i1, i1, i1)>
      %162 = "arith.constant"() <{value = 127 : i32}> : () -> i32
      %163 = "cute.static"() : () -> !cute.layout<"(16,(4)):(1,(16))">
      %164 = "cute.static"() : () -> !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %165 = "cute.static"() : () -> !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %166 = "arith.constant"() <{value = 14 : i32}> : () -> i32
      %167 = "arith.constant"() <{value = 13 : i32}> : () -> i32
      %168 = "arith.constant"() <{value = 138412048 : i32}> : () -> i32
      %169 = "cute.static"() : () -> !cute.layout<"(1,1,4,4):(0,0,2,2048)">
      %170 = "cute.static"() : () -> !cute.layout<"(1,1,4,4):(0,0,2,1024)">
      %171 = "cute.static"() : () -> !cute.layout<"((16384,1),4):((1,0),16384)">
      %172 = "cute.static"() : () -> !cute.layout<"((8192,1),4):((1,0),8192)">
      %173 = "arith.constant"() <{value = 49152 : i32}> : () -> i32
      %174 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %175 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %176 = "arith.constant"() <{value = 10000000 : i32}> : () -> i32
      %177 = "arith.constant"() <{value = true}> : () -> i1
      %178 = "arith.constant"() <{value = 32 : i64}> : () -> i64
      %179 = "arith.constant"() <{value = 2097152 : i32}> : () -> i32
      %180 = "cute.static"() : () -> !cute.shape<"(((128,64)),((1,4),1,1))">
      %181 = "cute.static"() : () -> !cute.stride<"(((1@0,1@1),0),64@0)">
      %182 = "cute.static"() : () -> !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %183 = "cute.static"() : () -> !cute.shape<"((128,256),1,1)">
      %184 = "cute.static"() : () -> !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %185 = "cute.static"() : () -> !cute.shape<"(128,256)">
      %186 = "arith.constant"() <{value = 128 : i64}> : () -> i64
      %187 = "cute.static"() : () -> !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %188 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %189 = "cute.static"() : () -> !cute.stride<"(1@1,1@0,64@0)">
      %190 = "cute.static"() : () -> !cute.stride<"((1@1,1@0),(128@1,64@0))">
      %191 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %192 = "cute.static"() : () -> !cute.int_tuple<"4">
      %193 = "cute.static"() : () -> !cute.int_tuple<"3">
      %194 = "cute.static"() : () -> !cute.int_tuple<"2">
      %195 = "cute.static"() : () -> !cute.int_tuple<"1">
      %196 = "arith.constant"() <{value = 512 : i32}> : () -> i32
      %197 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %198 = "cute.static"() : () -> !cute.int_tuple<"65536">
      %199 = "arith.constant"() <{value = -128 : i32}> : () -> i32
      %200 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %201 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %202 = "cute.static"() : () -> !cute.int_tuple<"80">
      %203 = "cute.static"() : () -> !cute.int_tuple<"64">
      %204 = "cute.static"() : () -> !cute.int_tuple<"88">
      %205 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %206 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %207 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %208 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %209 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %210 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %211 = "arith.muli"(%207, %209) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %212 = "arith.addi"(%206, %211) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %213 = "arith.muli"(%208, %209) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %214 = "arith.muli"(%213, %210) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %215 = "arith.addi"(%212, %214) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %216 = "arith.floordivsi"(%215, %205) : (i32, i32) -> i32
      %217 = "cute_nvgpu.arch.make_warp_uniform"(%216) : (i32) -> i32
      %218 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %219 = "nvvm.read.ptx.sreg.ctaid.y"() <{range = #llvm.constant_range<i32, 0, 65535>}> : () -> i32
      %220 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %221 = "cute.add_offset"(%220, %204) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %222 = "cute.add_offset"(%220, %203) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %223 = "cute.add_offset"(%220, %202) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %224 = "cute.recast_iter"(%223) : (!cute.ptr<i8, smem, align<16>>) -> !cute.ptr<i32, smem, align<16>>
      %225 = "cute.ptrtoint"(%221) : (!cute.ptr<i8, smem, align<8>>) -> i32
      %226 = "arith.addi"(%225, %162) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %227 = "arith.andi"(%226, %199) : (i32, i32) -> i32
      %228 = "arith.extsi"(%227) : (i32) -> i64
      %229 = "cute.assume"(%228) : (i64) -> !cute.i64<divby 128>
      %230 = "cute.inttoptr"(%229) : (!cute.i64<divby 128>) -> !cute.ptr<i8, smem, align<128>>
      %231 = "cute.add_offset"(%230, %198) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %232 = "cute.recast_iter"(%230) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %233 = "cute.recast_iter"(%231) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %234 = "arith.cmpi"(%217, %197) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%234)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      "cute_nvgpu.arch.sm100.alloc_tmem"(%196, %224) : (i32, !cute.ptr<i32, smem, align<16>>) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "cf.cond_br"(%234)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      "cute_nvgpu.prefetch_tma_desc"(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>) -> ()
      "cute_nvgpu.prefetch_tma_desc"(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>) -> ()
      "cf.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %235 = "cute.recast_iter"(%220) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<i64, smem, align<1024>>
      "cf.cond_br"(%234)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %236 = "builtin.unrealized_conversion_cast"(%235) : (!cute.ptr<i64, smem, align<1024>>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%236, %200) : (!llvm.ptr<3>, i32) -> ()
      %237 = "cute.add_offset"(%235, %195) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %238 = "builtin.unrealized_conversion_cast"(%237) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%238, %200) : (!llvm.ptr<3>, i32) -> ()
      %239 = "cute.add_offset"(%235, %194) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %240 = "builtin.unrealized_conversion_cast"(%239) : (!cute.ptr<i64, smem, align<16>>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%240, %200) : (!llvm.ptr<3>, i32) -> ()
      %241 = "cute.add_offset"(%235, %193) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %242 = "builtin.unrealized_conversion_cast"(%241) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%242, %200) : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %243 = "cute.add_offset"(%235, %192) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      "cf.cond_br"(%234)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %244 = "builtin.unrealized_conversion_cast"(%243) : (!cute.ptr<i64, smem, align<32>>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%244, %200) : (!llvm.ptr<3>, i32) -> ()
      %245 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
      %246 = "cute.add_offset"(%235, %245) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %247 = "builtin.unrealized_conversion_cast"(%246) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%247, %200) : (!llvm.ptr<3>, i32) -> ()
      %248 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
      %249 = "cute.add_offset"(%235, %248) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %250 = "builtin.unrealized_conversion_cast"(%249) : (!cute.ptr<i64, smem, align<16>>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%250, %200) : (!llvm.ptr<3>, i32) -> ()
      %251 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
      %252 = "cute.add_offset"(%235, %251) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %253 = "builtin.unrealized_conversion_cast"(%252) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%253, %200) : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      "nvvm.fence.mbarrier.init"() <{useIntrinsic = false}> : () -> ()
      "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
      %254 = "cute.recast_iter"(%222) : (!cute.ptr<i8, smem, align<64>>) -> !cute.ptr<i64, smem, align<64>>
      "cf.cond_br"(%234)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %255 = "builtin.unrealized_conversion_cast"(%254) : (!cute.ptr<i64, smem, align<64>>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%255, %200) : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %256 = "cute.add_offset"(%254, %195) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      "cf.cond_br"(%234)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %257 = "builtin.unrealized_conversion_cast"(%256) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.init.shared"(%257, %201) : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      "nvvm.fence.mbarrier.init"() <{useIntrinsic = false}> : () -> ()
      "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
      %258 = "cute.make_coord"(%218) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %259 = "cute.get_layout"(%arg5) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %260:2 = "cute.get_scalars"(%259) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> (i32, i32)
      %261 = "arith.ceildivsi"(%260#0, %201) : (i32, i32) -> i32
      %262 = "arith.ceildivsi"(%260#1, %191) : (i32, i32) -> i32
      %263 = "cute.make_shape"(%261, %262) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %264 = "cute.make_layout"(%263, %190) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,64),(?,?))">, !cute.stride<"((1@1,1@0),(128@1,64@0))">) -> !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %265:2 = "cute.get_scalars"(%264) <{only_dynamic}> : (!cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> (i32, i32)
      %266 = "cute.make_shape"(%265#1) : (i32) -> !cute.shape<"(128,64,?)">
      %267 = "cute.make_layout"(%266, %189) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,64,?)">, !cute.stride<"(1@1,1@0,64@0)">) -> !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %268 = "cute.crd2idx"(%258, %264) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %269 = "cute.get_iter"(%arg5) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.arith_tuple_iter<"(0,0)">
      %270 = "cute.add_offset"(%269, %268) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.arith_tuple_iter<"(0,?{div=128})">
      %271 = "cute.make_coord"(%219) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %272 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %273:2 = "cute.get_scalars"(%272) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> (i32, i32)
      %274 = "arith.ceildivsi"(%273#0, %188) : (i32, i32) -> i32
      %275 = "arith.ceildivsi"(%273#1, %191) : (i32, i32) -> i32
      %276 = "cute.make_shape"(%274, %275) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %277 = "cute.make_layout"(%276, %187) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((256,64),(?,?))">, !cute.stride<"((1@1,1@0),(256@1,64@0))">) -> !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %278:2 = "cute.get_scalars"(%277) <{only_dynamic}> : (!cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> (i32, i32)
      %279 = "cute.make_shape"(%278#1) : (i32) -> !cute.shape<"(256,64,?)">
      %280 = "cute.make_layout"(%279, %189) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(256,64,?)">, !cute.stride<"(1@1,1@0,64@0)">) -> !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %281 = "cute.crd2idx"(%271, %277) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %282 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.arith_tuple_iter<"(0,0)">
      %283 = "cute.add_offset"(%282, %281) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.arith_tuple_iter<"(0,?{div=256})">
      %284 = "cute.make_coord"(%218, %219) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %285 = "cute.get_layout"(%arg8) : (!memref_gmem_f16_) -> !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %286:3 = "cute.get_scalars"(%285) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> (i32, i32, i64)
      %287 = "arith.ceildivsi"(%286#0, %201) : (i32, i32) -> i32
      %288 = "arith.muli"(%286#2, %186) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %289 = "arith.ceildivsi"(%286#1, %188) : (i32, i32) -> i32
      %290 = "cute.make_shape"(%287, %289) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %291 = "cute.assume"(%286#2) : (i64) -> !cute.i64<divby 8192>
      %292 = "cute.assume"(%288) : (i64) -> !cute.i64<divby 1048576>
      %293 = "cute.make_stride"(%291, %292) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %294 = "cute.make_layout"(%290, %293) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,256),(?,?))">, !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %295:4 = "cute.get_scalars"(%294) <{only_dynamic}> : (!cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> (i32, i32, i64, i64)
      %296 = "cute.assume"(%295#2) : (i64) -> !cute.i64<divby 8192>
      %297 = "cute.make_stride"(%296) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %298 = "cute.make_layout"(%185, %297) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,256)">, !cute.stride<"(?{i64 div=8192},1)">) -> !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %299 = "cute.crd2idx"(%284, %294) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %300 = "cute.get_iter"(%arg8) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<32>>
      %301 = "cute.add_offset"(%300, %299) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %302 = "cute.get_scalars"(%267) <{only_dynamic}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> i32
      %303 = "cute.make_shape"(%302) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %304 = "cute.make_layout"(%303, %184) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,16),1,4,?)">, !cute.stride<"((1@1,1@0),0,16@0,64@0)">) -> !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %305 = "cute.get_scalars"(%280) <{only_dynamic}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> i32
      %306 = "cute.make_shape"(%305) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %307 = "cute.make_layout"(%306, %184) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((256,16),1,4,?)">, !cute.stride<"((1@1,1@0),0,16@0,64@0)">) -> !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %308 = "cute.get_scalars"(%298) <{only_dynamic}> : (!cute.layout<"(128,256):(?{i64 div=8192},1)">) -> i64
      %309 = "cute.assume"(%308) : (i64) -> !cute.i64<divby 8192>
      %310 = "cute.make_stride"(%309) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %311 = "cute.make_layout"(%183, %310) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,256),1,1)">, !cute.stride<"((?{i64 div=8192},1),0,0)">) -> !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %312 = "cute_nvgpu.make_umma_smem_desc"(%232) <{layout = #cute.layout<"((128,16),1,4,4):((64,1),0,16,8192)">, major = #cute_nvgpu.major<k>}> : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>) -> !cute_nvgpu.smem_desc
      %313 = "cute_nvgpu.make_umma_smem_desc"(%233) <{layout = #cute.layout<"((256,16),1,4,4):((64,1),0,16,16384)">, major = #cute_nvgpu.major<k>}> : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>) -> !cute_nvgpu.smem_desc
      %314 = "cute.get_scalars"(%304) <{only_dynamic}> : (!cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">) -> i32
      %315 = "cute.make_shape"(%314) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %316 = "cute.make_layout"(%315, %182) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((128,16),1,4),?)">, !cute.stride<"(((1@1,1@0),0,16@0),64@0)">) -> !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %317 = "cute.get_scalars"(%316) <{only_dynamic}> : (!cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">) -> i32
      %318 = "cute.make_shape"(%317) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %319 = "cute.make_layout"(%318, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((64,128),1),?)">, !cute.stride<"(((1@0,1@1),0),64@0)">) -> !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %320 = "cute.get_scalars"(%307) <{only_dynamic}> : (!cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">) -> i32
      %321 = "cute.make_shape"(%320) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %322 = "cute.make_layout"(%321, %182) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((256,16),1,4),?)">, !cute.stride<"(((1@1,1@0),0,16@0),64@0)">) -> !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %323 = "cute.get_scalars"(%322) <{only_dynamic}> : (!cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">) -> i32
      %324 = "cute.make_shape"(%323) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %325 = "cute.make_layout"(%324, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((64,256),1),?)">, !cute.stride<"(((1@0,1@1),0),64@0)">) -> !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      "llvm.inline_asm"(%200, %201) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %326 = "cute_nvgpu.arch.sm100.retrieve_tmem_ptr"(%224) : (!cute.ptr<i32, smem, align<16>>) -> !cute.ptr<f32, tmem, align<16>>
      %327 = "cute.get_scalars"(%311) <{only_dynamic}> : (!cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">) -> i64
      %328 = "cute.assume"(%327) : (i64) -> !cute.i64<divby 8192>
      %329 = "cute.make_stride"(%328) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %330 = "cute.make_layout"(%180, %329) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((128,64)),((1,4),1,1))">, !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">) -> !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %331 = "arith.divsi"(%206, %205) : (i32, i32) -> i32
      %332 = "arith.muli"(%331, %179) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %333 = "cute.assume"(%332) : (i32) -> !cute.i32<divby 2097152>
      %334 = "cute.make_int_tuple"(%333) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %335 = "cute.add_offset"(%326, %334) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %336 = "cute.get_scalars"(%330) <{only_dynamic}> : (!cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">) -> i64
      %337 = "arith.muli"(%336, %178) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %338 = "arith.remsi"(%206, %205) : (i32, i32) -> i32
      %339 = "arith.extsi"(%338) : (i32) -> i64
      %340 = "arith.muli"(%339, %336) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %341 = "arith.extsi"(%331) : (i32) -> i64
      %342 = "arith.muli"(%341, %337) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %343 = "arith.addi"(%340, %342) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %344 = "cute.assume"(%343) : (i64) -> !cute.i64<divby 8192>
      %345 = "cute.make_int_tuple"(%344) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %346 = "cute.add_offset"(%301, %345) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %347 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %348 = "cute.memref.alloca"() : () -> !memref_rmem_f16_
      %349 = "cute.size"(%267) <{mode = array<i32: 2>}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %350 = "cute.get_leaves"(%349) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %351 = "cute.get_scalars"(%350) : (!cute.int_tuple<"?">) -> i32
      "cf.cond_br"(%234)[^bb13, ^bb44] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %352 = "builtin.unrealized_conversion_cast"(%256) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%352, %200, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %353 = "cute_nvgpu.atom.make_exec_tma"(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %354 = "cute_nvgpu.atom.make_exec_tma"(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %355 = "arith.minsi"(%351, %174) : (i32, i32) -> i32
      %356 = "cute_nvgpu.atom.get_value"(%353) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> i64
      %357 = "cute_nvgpu.atom.get_value"(%354) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> i64
      "cf.br"(%197, %197, %200, %197)[^bb14] : (i32, i32, i32, i32) -> ()
    ^bb14(%358: i32, %359: i32, %360: i32, %361: i32):  // 2 preds: ^bb13, ^bb21
      %362 = "arith.cmpi"(%358, %355) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%362)[^bb15, ^bb22] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %363 = "cute.make_int_tuple"(%359) : (i32) -> !cute.int_tuple<"?">
      %364 = "cute.add_offset"(%243, %363) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %365 = "builtin.unrealized_conversion_cast"(%364) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%365, %360, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %366 = "nvvm.elect.sync"() : () -> i1
      "cf.cond_br"(%366)[^bb16, ^bb17] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb16:  // pred: ^bb15
      %367 = "cute.add_offset"(%235, %363) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %368 = "builtin.unrealized_conversion_cast"(%367) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.txn"(%368, %173) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb17] : () -> ()
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %369 = "arith.addi"(%359, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %370 = "arith.addi"(%361, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %371 = "arith.cmpi"(%369, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %372 = "arith.select"(%371, %197, %369) : (i1, i32, i32) -> i32
      "cf.cond_br"(%371)[^bb18, ^bb19] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb18:  // pred: ^bb17
      %373 = "arith.xori"(%360, %200) : (i32, i32) -> i32
      "cf.br"(%373)[^bb20] : (i32) -> ()
    ^bb19:  // pred: ^bb17
      "cf.br"(%360)[^bb20] : (i32) -> ()
    ^bb20(%374: i32):  // 2 preds: ^bb18, ^bb19
      "cf.br"()[^bb21] : () -> ()
    ^bb21:  // pred: ^bb20
      %375 = "cute.make_coord"(%361) : (i32) -> !cute.coord<"(_,?)">
      %376 = "cute.crd2idx"(%375, %319) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %377 = "cute.add_offset"(%270, %376) : (!cute.arith_tuple_iter<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
      %378 = "cute.deref_arith_tuple_iter"(%377) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %379:2 = "cute.get_leaves"(%378) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">)
      %380 = "cute.make_coord"(%359) : (i32) -> !cute.coord<"(_,?)">
      %381 = "cute.crd2idx"(%380, %172) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %382 = "cute.add_offset"(%232, %381) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %383 = "cute.add_offset"(%235, %363) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %384 = "cute.make_int_tuple"(%379#0, %379#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %385 = "cute.make_arith_tuple_iter"(%384) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
      %386 = "cute_nvgpu.atom.set_value"(%353, %383) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %387 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<i64, smem>) -> !cute.ptr<smem, align<8>>
      %388 = "cute_nvgpu.get_tma_desc_addr"(%386) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %389 = "cute.deref_arith_tuple_iter"(%385) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %390:2 = "cute.get_scalars"(%389) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (i32, i32)
      "cute_nvgpu.arch.copy.SM100.tma_load"(%388, %382, %387, %390#0, %390#1, %356) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
      %391 = "cute.crd2idx"(%375, %325) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %392 = "cute.add_offset"(%283, %391) : (!cute.arith_tuple_iter<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
      %393 = "cute.deref_arith_tuple_iter"(%392) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %394:2 = "cute.get_leaves"(%393) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">)
      %395 = "cute.crd2idx"(%380, %171) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %396 = "cute.add_offset"(%233, %395) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %397 = "cute.make_int_tuple"(%394#0, %394#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %398 = "cute.make_arith_tuple_iter"(%397) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
      %399 = "cute_nvgpu.atom.set_value"(%354, %383) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %400 = "cute_nvgpu.get_tma_desc_addr"(%399) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %401 = "cute.deref_arith_tuple_iter"(%398) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %402:2 = "cute.get_scalars"(%401) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (i32, i32)
      "cute_nvgpu.arch.copy.SM100.tma_load"(%400, %396, %387, %402#0, %402#1, %357) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
      %403 = "arith.addi"(%358, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%403, %372, %374, %370)[^bb14] : (i32, i32, i32, i32) -> ()
    ^bb22:  // pred: ^bb14
      "cf.br"(%197, %361, %359, %360, %197, %197, %197, %161)[^bb23] : (i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> ()
    ^bb23(%404: i32, %405: i32, %406: i32, %407: i32, %408: i32, %409: i32, %410: i32, %411: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb22, ^bb40
      %412 = "arith.cmpi"(%404, %351) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%412)[^bb24, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %413 = "builtin.unrealized_conversion_cast"(%411) : (!llvm.struct<(i1, i1, i1)>) -> !mma_f16_f16_f32_128x256x16_
      %414 = "arith.addi"(%404, %355) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %415 = "arith.cmpi"(%414, %351) <{predicate = 6 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%415)[^bb25, ^bb32] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb25:  // pred: ^bb24
      %416 = "cute.make_int_tuple"(%406) : (i32) -> !cute.int_tuple<"?">
      %417 = "cute.add_offset"(%243, %416) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %418 = "builtin.unrealized_conversion_cast"(%417) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%418, %407, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %419 = "nvvm.elect.sync"() : () -> i1
      "cf.cond_br"(%419)[^bb26, ^bb27] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb26:  // pred: ^bb25
      %420 = "cute.add_offset"(%235, %416) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %421 = "builtin.unrealized_conversion_cast"(%420) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.txn"(%421, %173) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
      "cf.br"()[^bb27] : () -> ()
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %422 = "arith.addi"(%406, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %423 = "arith.addi"(%405, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %424 = "arith.cmpi"(%422, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %425 = "arith.select"(%424, %197, %422) : (i1, i32, i32) -> i32
      "cf.cond_br"(%424)[^bb28, ^bb29] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb28:  // pred: ^bb27
      %426 = "arith.xori"(%407, %200) : (i32, i32) -> i32
      "cf.br"(%426)[^bb30] : (i32) -> ()
    ^bb29:  // pred: ^bb27
      "cf.br"(%407)[^bb30] : (i32) -> ()
    ^bb30(%427: i32):  // 2 preds: ^bb28, ^bb29
      "cf.br"()[^bb31] : () -> ()
    ^bb31:  // pred: ^bb30
      %428 = "cute.make_coord"(%405) : (i32) -> !cute.coord<"(_,?)">
      %429 = "cute.crd2idx"(%428, %319) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %430 = "cute.add_offset"(%270, %429) : (!cute.arith_tuple_iter<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
      %431 = "cute.deref_arith_tuple_iter"(%430) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %432:2 = "cute.get_leaves"(%431) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">)
      %433 = "cute.make_coord"(%406) : (i32) -> !cute.coord<"(_,?)">
      %434 = "cute.crd2idx"(%433, %172) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %435 = "cute.add_offset"(%232, %434) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %436 = "cute.add_offset"(%235, %416) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %437 = "cute.make_int_tuple"(%432#0, %432#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %438 = "cute.make_arith_tuple_iter"(%437) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
      %439 = "cute_nvgpu.atom.set_value"(%353, %436) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %440 = "builtin.unrealized_conversion_cast"(%436) : (!cute.ptr<i64, smem>) -> !cute.ptr<smem, align<8>>
      %441 = "cute_nvgpu.atom.get_value"(%353) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> i64
      %442 = "cute_nvgpu.get_tma_desc_addr"(%439) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %443 = "cute.deref_arith_tuple_iter"(%438) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %444:2 = "cute.get_scalars"(%443) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (i32, i32)
      "cute_nvgpu.arch.copy.SM100.tma_load"(%442, %435, %440, %444#0, %444#1, %441) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
      %445 = "cute.crd2idx"(%428, %325) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %446 = "cute.add_offset"(%283, %445) : (!cute.arith_tuple_iter<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
      %447 = "cute.deref_arith_tuple_iter"(%446) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %448:2 = "cute.get_leaves"(%447) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">)
      %449 = "cute.crd2idx"(%433, %171) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %450 = "cute.add_offset"(%233, %449) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %451 = "cute.make_int_tuple"(%448#0, %448#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %452 = "cute.make_arith_tuple_iter"(%451) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
      %453 = "cute_nvgpu.atom.set_value"(%354, %436) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %454 = "cute_nvgpu.atom.get_value"(%354) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> i64
      %455 = "cute_nvgpu.get_tma_desc_addr"(%453) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %456 = "cute.deref_arith_tuple_iter"(%452) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %457:2 = "cute.get_scalars"(%456) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (i32, i32)
      "cute_nvgpu.arch.copy.SM100.tma_load"(%455, %450, %440, %457#0, %457#1, %454) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
      "cf.br"(%425, %427, %423)[^bb33] : (i32, i32, i32) -> ()
    ^bb32:  // pred: ^bb24
      "cf.br"(%406, %407, %405)[^bb33] : (i32, i32, i32) -> ()
    ^bb33(%458: i32, %459: i32, %460: i32):  // 2 preds: ^bb31, ^bb32
      "cf.br"()[^bb34] : () -> ()
    ^bb34:  // pred: ^bb33
      %461 = "cute.make_int_tuple"(%409) : (i32) -> !cute.int_tuple<"?">
      %462 = "cute.add_offset"(%235, %461) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %463 = "builtin.unrealized_conversion_cast"(%462) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%463, %410, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %464 = "arith.addi"(%409, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %465 = "arith.addi"(%408, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %466 = "arith.cmpi"(%464, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %467 = "arith.select"(%466, %197, %464) : (i1, i32, i32) -> i32
      "cf.cond_br"(%466)[^bb35, ^bb36] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb35:  // pred: ^bb34
      %468 = "arith.xori"(%410, %200) : (i32, i32) -> i32
      "cf.br"(%468)[^bb37] : (i32) -> ()
    ^bb36:  // pred: ^bb34
      "cf.br"(%410)[^bb37] : (i32) -> ()
    ^bb37(%469: i32):  // 2 preds: ^bb35, ^bb36
      "cf.br"()[^bb38] : () -> ()
    ^bb38:  // pred: ^bb37
      %470 = "cute.make_coord"(%409) : (i32) -> !cute.coord<"(_,_,0,?)">
      %471 = "cute.crd2idx"(%470, %170) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %472 = "cute.add_offset"(%312, %471) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %473 = "cute.crd2idx"(%470, %169) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %474 = "cute.add_offset"(%313, %473) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
      %475 = "cute_nvgpu.atom.get_value"(%413) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_a>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
      %476 = "cute_nvgpu.atom.get_value"(%413) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_b>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
      %477 = "cute_nvgpu.atom.get_value"(%413) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
      %478 = "arith.extui"(%475) : (i1) -> i32
      %479 = "arith.extui"(%476) : (i1) -> i32
      %480 = "arith.shli"(%478, %167) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %481 = "arith.shli"(%479, %166) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %482 = "arith.ori"(%480, %168) : (i32, i32) -> i32
      %483 = "arith.ori"(%482, %481) : (i32, i32) -> i32
      "cute_nvgpu.arch.mma.SM100.umma"(%472, %474, %326, %483, %477) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %484 = "cute_nvgpu.atom.set_value"(%413, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
      %485 = "cute.make_coord"(%409) : (i32) -> !cute.coord<"(_,_,1,?)">
      %486 = "cute.crd2idx"(%485, %170) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %487 = "cute.add_offset"(%312, %486) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %488 = "cute.crd2idx"(%485, %169) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %489 = "cute.add_offset"(%313, %488) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      "cute_nvgpu.arch.mma.SM100.umma"(%487, %489, %326, %483, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %490 = "cute_nvgpu.atom.set_value"(%484, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
      %491 = "cute.make_coord"(%409) : (i32) -> !cute.coord<"(_,_,2,?)">
      %492 = "cute.crd2idx"(%491, %170) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %493 = "cute.add_offset"(%312, %492) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %494 = "cute.crd2idx"(%491, %169) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
      %495 = "cute.add_offset"(%313, %494) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      "cute_nvgpu.arch.mma.SM100.umma"(%493, %495, %326, %483, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %496 = "cute_nvgpu.atom.set_value"(%490, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
      %497 = "cute.make_coord"(%409) : (i32) -> !cute.coord<"(_,_,3,?)">
      %498 = "cute.crd2idx"(%497, %170) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %499 = "cute.add_offset"(%312, %498) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %500 = "cute.crd2idx"(%497, %169) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %501 = "cute.add_offset"(%313, %500) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      "cute_nvgpu.arch.mma.SM100.umma"(%499, %501, %326, %483, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %502 = "cute_nvgpu.atom.set_value"(%496, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
      %503 = "builtin.unrealized_conversion_cast"(%502) : (!mma_f16_f16_f32_128x256x16_) -> !llvm.struct<(i1, i1, i1)>
      %504 = "nvvm.elect.sync"() : () -> i1
      "cf.cond_br"(%504)[^bb39, ^bb40] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb39:  // pred: ^bb38
      %505 = "cute.add_offset"(%243, %461) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %506 = "builtin.unrealized_conversion_cast"(%505) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.tcgen05.commit.arrive"(%506) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
      "cf.br"()[^bb40] : () -> ()
    ^bb40:  // 2 preds: ^bb38, ^bb39
      %507 = "arith.addi"(%404, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%507, %460, %458, %459, %465, %467, %469, %503)[^bb23] : (i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> ()
    ^bb41:  // pred: ^bb23
      %508 = "nvvm.elect.sync"() : () -> i1
      "cf.cond_br"(%508)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %509 = "cute.derefine"(%254) : (!cute.ptr<i64, smem, align<64>>) -> !cute.ptr<i64, smem>
      %510 = "builtin.unrealized_conversion_cast"(%509) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.tcgen05.commit.arrive"(%510) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
      "cf.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      "cf.br"()[^bb44] : () -> ()
    ^bb44:  // 2 preds: ^bb12, ^bb43
      "cf.cond_br"(%234)[^bb45, ^bb46] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb45:  // pred: ^bb44
      "cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit"() : () -> ()
      "cf.br"()[^bb46] : () -> ()
    ^bb46:  // 2 preds: ^bb44, ^bb45
      %511 = "cute.derefine"(%254) : (!cute.ptr<i64, smem, align<64>>) -> !cute.ptr<i64, smem>
      %512 = "builtin.unrealized_conversion_cast"(%511) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%512, %197, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %513 = "cute.get_iter"(%347) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %514 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %515 = "cute.get_iter"(%348) : (!memref_rmem_f16_) -> !cute.ptr<f16, rmem, align<32>>
      "cf.br"(%197)[^bb47] : (i32) -> ()
    ^bb47(%516: i32):  // 2 preds: ^bb46, ^bb51
      %517 = "arith.cmpi"(%516, %175) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%517)[^bb48, ^bb52] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb48:  // pred: ^bb47
      %518 = "cute.make_coord"(%516) : (i32) -> !cute.coord<"(_,_,?)">
      %519 = "cute.crd2idx"(%518, %165) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %520 = "cute.add_offset"(%335, %519) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      %521 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%520) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      "llvm.store"(%521, %514) <{ordering = 0 : i64}> : (vector<64xi32>, !llvm.ptr) -> ()
      %522 = "cute.memref.load_vec"(%347) : (!memref_rmem_f32_) -> vector<64xf32>
      %523 = "arith.truncf"(%522) : (vector<64xf32>) -> vector<64xf16>
      "cute.memref.store_vec"(%523, %348) : (vector<64xf16>, !memref_rmem_f16_) -> ()
      %524 = "cute.crd2idx"(%518, %164) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %525 = "cute.add_offset"(%346, %524) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      "cf.br"(%197)[^bb49] : (i32) -> ()
    ^bb49(%526: i32):  // 2 preds: ^bb48, ^bb50
      %527 = "arith.cmpi"(%526, %175) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%527)[^bb50, ^bb51] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb50:  // pred: ^bb49
      %528 = "cute.make_coord"(%526) : (i32) -> !cute.coord<"(_,?)">
      %529 = "cute.crd2idx"(%528, %163) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %530 = "cute.add_offset"(%515, %529) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
      %531 = "cute.add_offset"(%525, %529) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
      %532 = "builtin.unrealized_conversion_cast"(%530) : (!cute.ptr<f16, rmem, align<32>>) -> !llvm.ptr
      %533 = "builtin.unrealized_conversion_cast"(%531) : (!cute.ptr<f16, gmem, align<32>>) -> !llvm.ptr<1>
      %534 = "llvm.load"(%532) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<16xf16>
      "llvm.store"(%534, %533) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<16xf16>, !llvm.ptr<1>) -> ()
      %535 = "arith.addi"(%526, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%535)[^bb49] : (i32) -> ()
    ^bb51:  // pred: ^bb49
      %536 = "arith.addi"(%516, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%536)[^bb47] : (i32) -> ()
    ^bb52:  // pred: ^bb47
      %537 = "builtin.unrealized_conversion_cast"(%256) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.txn"(%537, %200) <{kind = #nvvm.mbar_txn_kind<arrive>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
      "llvm.inline_asm"(%200) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "cf.cond_br"(%234)[^bb53, ^bb54] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb53:  // pred: ^bb52
      "cute_nvgpu.arch.sm100.dealloc_tmem"(%326, %196) : (!cute.ptr<f32, tmem, align<16>>, i32) -> ()
      "cf.br"()[^bb54] : () -> ()
    ^bb54:  // 2 preds: ^bb52, ^bb53
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f16_, !memref_gmem_f16_, !memref_gmem_f16_) -> i32, sym_name = "cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921"}> ({
  ^bb0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_):
    %0 = "arith.constant"() <{value = 196736 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 4539628424389459968 : i64}> : () -> i64
    %2 = "arith.constant"() <{value = 287506 : i64}> : () -> i64
    %3 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %5 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %6 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %7 = "arith.constant"() <{value = 255 : i64}> : () -> i64
    %8 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
    %9 = "cute.static"() : () -> !cute.stride<"(1@1,1@0)">
    %10 = "arith.constant"() <{value = 127 : i64}> : () -> i64
    %11 = "arith.constant"() <{value = 15 : i64}> : () -> i64
    %12 = "arith.constant"() <{value = 36 : i64}> : () -> i64
    %13 = "arith.constant"() <{value = 32 : i64}> : () -> i64
    %14 = "arith.constant"() <{value = 21 : i64}> : () -> i64
    %15 = "arith.constant"() <{value = 131072 : i64}> : () -> i64
    %16 = "arith.constant"() <{value = 9007199254740991 : i64}> : () -> i64
    %17 = "arith.constant"() <{value = 4 : i64}> : () -> i64
    %18 = "arith.constant"() <{value = 4294967295 : i64}> : () -> i64
    %19 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %20 = "arith.constant"() <{value = 8 : i64}> : () -> i64
    %21 = "arith.constant"() <{value = 2 : i64}> : () -> i64
    %22 = "arith.constant"() <{value = 1 : i64}> : () -> i64
    %23 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %24 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %25 = "arith.constant"() <{value = false}> : () -> i1
    %26 = "cute.make_atom"() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %27 = "cute_nvgpu.atom.set_value"(%26, %25) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, i1) -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %28 = "cute_nvgpu.atom.set_value"(%27, %25) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_a>}> : (!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, i1) -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %29 = "cute_nvgpu.atom.set_value"(%28, %25) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_b>}> : (!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, i1) -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %30 = "cute.make_tiled_mma"(%29) : (!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>) -> !mma_f16_f16_f32_128x256x16_
    %31 = "llvm.alloca"(%24) <{alignment = 64 : i64, elem_type = i64}> : (i32) -> !llvm.ptr
    %32 = "cute.get_iter"(%arg0) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<32>>
    %33 = "cute.get_layout"(%arg0) : (!memref_gmem_f16_) -> !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %34:3 = "cute.get_scalars"(%33) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> (i32, i32, i64)
    %35 = "arith.extui"(%34#1) : (i32) -> i64
    %36 = "arith.extui"(%34#0) : (i32) -> i64
    %37 = "arith.muli"(%34#2, %21) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %38 = "cute.ptrtoint"(%32) : (!cute.ptr<f16, gmem, align<32>>) -> i64
    %39 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %39) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %40 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %40) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %41 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %41) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %42 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %42) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %43 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %43) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %44 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %44) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %45 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 6>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %45) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %46 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 7>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %46) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %47 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 8>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %47) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %48 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 9>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %48) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %49 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 10>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %49) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %50 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 11>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %50) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %51 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 12>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %51) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %52 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 13>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %52) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %53 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 14>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %53) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %54 = "llvm.getelementptr"(%31) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 15>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %54) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %55 = "arith.divui"(%38, %19) : (i64, i64) -> i64
    %56 = "arith.andi"(%55, %16) : (i64, i64) -> i64
    %57 = "arith.shli"(%56, %17) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    "llvm.store"(%57, %39) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %58 = "arith.subi"(%36, %22) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %59 = "arith.muli"(%58, %37) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %60 = "arith.muli"(%35, %19) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %61 = "arith.divui"(%60, %20) : (i64, i64) -> i64
    %62 = "arith.addi"(%61, %59) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %63 = "arith.cmpi"(%62, %15) <{predicate = 9 : i64}> : (i64, i64) -> i1
    %64 = "arith.extui"(%63) : (i1) -> i64
    %65 = "arith.shli"(%64, %14) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %66 = "arith.divui"(%37, %19) : (i64, i64) -> i64
    %67 = "arith.shli"(%66, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %68 = "arith.ori"(%65, %67) : (i64, i64) -> i64
    %69 = "arith.ori"(%68, %2) : (i64, i64) -> i64
    "llvm.store"(%69, %40) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%23, %41) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %70 = "arith.shrui"(%37, %12) : (i64, i64) -> i64
    %71 = "arith.andi"(%70, %11) : (i64, i64) -> i64
    %72 = "arith.shli"(%71, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    "llvm.store"(%72, %42) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %73 = "arith.subi"(%35, %22) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %74 = "arith.andi"(%73, %18) : (i64, i64) -> i64
    %75 = "arith.shli"(%58, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %76 = "arith.ori"(%74, %75) : (i64, i64) -> i64
    "llvm.store"(%76, %43) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%23, %44) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%1, %45) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%10, %46) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %77 = "builtin.unrealized_conversion_cast"(%31) : (!llvm.ptr) -> !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %78 = "cute.ptrtoint"(%77) : (!cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>) -> i64
    %79 = "llvm.inttoptr"(%78) : (i64) -> !llvm.ptr
    %80 = "llvm.load"(%79) <{nontemporal, ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.struct<(array<16 x i64>)>
    %81 = "builtin.unrealized_conversion_cast"(%80) : (!llvm.struct<(array<16 x i64>)>) -> !cute_nvgpu.tma_descriptor_tiled
    %82 = "cute.make_atom"() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>
    %83 = "cute_nvgpu.atom.set_value"(%82, %81) <{field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>}> : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>, !cute_nvgpu.tma_descriptor_tiled) -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>
    %84 = "cute.get_shape"(%33) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %85 = "cute.make_layout"(%84, %9) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8192})">, !cute.stride<"(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %86 = "cute.make_arith_tuple_iter"(%8) : (!cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(0,0)">
    %87 = "cute.make_view"(%86, %85) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %88 = "llvm.alloca"(%24) <{alignment = 64 : i64, elem_type = i64}> : (i32) -> !llvm.ptr
    %89 = "cute.get_iter"(%arg1) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<32>>
    %90 = "cute.get_layout"(%arg1) : (!memref_gmem_f16_) -> !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %91:3 = "cute.get_scalars"(%90) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> (i32, i32, i64)
    %92 = "arith.extui"(%91#1) : (i32) -> i64
    %93 = "arith.extui"(%91#0) : (i32) -> i64
    %94 = "arith.muli"(%91#2, %21) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %95 = "cute.ptrtoint"(%89) : (!cute.ptr<f16, gmem, align<32>>) -> i64
    %96 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %96) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %97 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %97) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %98 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %98) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %99 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %99) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %100 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %100) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %101 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %101) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %102 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 6>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %102) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %103 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 7>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %103) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %104 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 8>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %104) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %105 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 9>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %105) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %106 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 10>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %106) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %107 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 11>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %107) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %108 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 12>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %108) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %109 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 13>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %109) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %110 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 14>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %110) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %111 = "llvm.getelementptr"(%88) <{elem_type = !llvm.array<16 x i64>, rawConstantIndices = array<i32: 0, 15>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%23, %111) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %112 = "arith.divui"(%95, %19) : (i64, i64) -> i64
    %113 = "arith.andi"(%112, %16) : (i64, i64) -> i64
    %114 = "arith.shli"(%113, %17) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    "llvm.store"(%114, %96) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %115 = "arith.subi"(%93, %22) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %116 = "arith.muli"(%115, %94) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %117 = "arith.muli"(%92, %19) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %118 = "arith.divui"(%117, %20) : (i64, i64) -> i64
    %119 = "arith.addi"(%118, %116) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %120 = "arith.cmpi"(%119, %15) <{predicate = 9 : i64}> : (i64, i64) -> i1
    %121 = "arith.extui"(%120) : (i1) -> i64
    %122 = "arith.shli"(%121, %14) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %123 = "arith.divui"(%94, %19) : (i64, i64) -> i64
    %124 = "arith.shli"(%123, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %125 = "arith.ori"(%122, %124) : (i64, i64) -> i64
    %126 = "arith.ori"(%125, %2) : (i64, i64) -> i64
    "llvm.store"(%126, %97) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%23, %98) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %127 = "arith.shrui"(%94, %12) : (i64, i64) -> i64
    %128 = "arith.andi"(%127, %11) : (i64, i64) -> i64
    %129 = "arith.shli"(%128, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    "llvm.store"(%129, %99) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %130 = "arith.subi"(%92, %22) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %131 = "arith.andi"(%130, %18) : (i64, i64) -> i64
    %132 = "arith.shli"(%115, %13) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %133 = "arith.ori"(%131, %132) : (i64, i64) -> i64
    "llvm.store"(%133, %100) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%23, %101) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%1, %102) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    "llvm.store"(%7, %103) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %134 = "builtin.unrealized_conversion_cast"(%88) : (!llvm.ptr) -> !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %135 = "cute.ptrtoint"(%134) : (!cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>) -> i64
    %136 = "llvm.inttoptr"(%135) : (i64) -> !llvm.ptr
    %137 = "llvm.load"(%136) <{nontemporal, ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.struct<(array<16 x i64>)>
    %138 = "builtin.unrealized_conversion_cast"(%137) : (!llvm.struct<(array<16 x i64>)>) -> !cute_nvgpu.tma_descriptor_tiled
    %139 = "cute.make_atom"() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>
    %140 = "cute_nvgpu.atom.set_value"(%139, %138) <{field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>}> : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>, !cute_nvgpu.tma_descriptor_tiled) -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>
    %141 = "cute.get_shape"(%90) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %142 = "cute.make_layout"(%141, %9) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8192})">, !cute.stride<"(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %143 = "cute.make_view"(%86, %142) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %144 = "cute.get_layout"(%arg2) : (!memref_gmem_f16_) -> !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %145 = "cute.get_shape"(%144) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %146:2 = "cute.get_leaves"(%145) : (!cute.shape<"(?,?{div=8192})">) -> (!cute.shape<"?">, !cute.shape<"?{div=8192}">)
    %147 = "cute.to_int_tuple"(%146#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %148 = "cute.to_int_tuple"(%146#1) : (!cute.shape<"?{div=8192}">) -> !cute.int_tuple<"?{div=8192}">
    %149 = "cute.make_int_tuple"(%147, %148) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %150:2 = "cute.get_scalars"(%149) <{only_dynamic}> : (!cute.int_tuple<"(?,?{div=8192},1)">) -> (i32, i32)
    %151 = "arith.ceildivsi"(%150#0, %6) : (i32, i32) -> i32
    %152 = "arith.ceildivsi"(%150#1, %5) : (i32, i32) -> i32
    %153 = "cute.make_int_tuple"(%151, %152) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %154:3 = "cute.get_leaves"(%153) : (!cute.int_tuple<"(?,?,1)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"1">)
    %155 = "cute.get_scalars"(%154#0) : (!cute.int_tuple<"?">) -> i32
    %156 = "cute.get_scalars"(%154#1) : (!cute.int_tuple<"?">) -> i32
    %157 = "cuda.cast"(%23) : (i64) -> !cuda.stream
    %158 = "cuda.launch_cfg.create"(%6, %4, %4, %0, %155, %156, %4, %157) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%158, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%158, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %159 = "cuda.launch_ex"(%158, %30, %83, %87, %140, %143, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0}> : (!cuda.launch_cfg<max_attrs = 3>, !mma_f16_f16_f32_128x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %160 = "cuda.cast"(%159) : (!cuda.result) -> i32
    "cuda.return_if_error"(%160) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
