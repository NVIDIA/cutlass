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
      "scf.if"(%234) ({
        "cute_nvgpu.arch.sm100.alloc_tmem"(%196, %224) : (i32, !cute.ptr<i32, smem, align<16>>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "scf.if"(%234) ({
        "cute_nvgpu.prefetch_tma_desc"(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>) -> ()
        "cute_nvgpu.prefetch_tma_desc"(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %235 = "cute.recast_iter"(%220) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<i64, smem, align<1024>>
      "scf.if"(%234) ({
        %509 = "builtin.unrealized_conversion_cast"(%235) : (!cute.ptr<i64, smem, align<1024>>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%509, %200) : (!llvm.ptr<3>, i32) -> ()
        %510 = "cute.add_offset"(%235, %195) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %511 = "builtin.unrealized_conversion_cast"(%510) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%511, %200) : (!llvm.ptr<3>, i32) -> ()
        %512 = "cute.add_offset"(%235, %194) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %513 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<i64, smem, align<16>>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%513, %200) : (!llvm.ptr<3>, i32) -> ()
        %514 = "cute.add_offset"(%235, %193) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %515 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%515, %200) : (!llvm.ptr<3>, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %236 = "cute.add_offset"(%235, %192) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      "scf.if"(%234) ({
        %499 = "builtin.unrealized_conversion_cast"(%236) : (!cute.ptr<i64, smem, align<32>>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%499, %200) : (!llvm.ptr<3>, i32) -> ()
        %500 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
        %501 = "cute.add_offset"(%235, %500) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %502 = "builtin.unrealized_conversion_cast"(%501) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%502, %200) : (!llvm.ptr<3>, i32) -> ()
        %503 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
        %504 = "cute.add_offset"(%235, %503) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %505 = "builtin.unrealized_conversion_cast"(%504) : (!cute.ptr<i64, smem, align<16>>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%505, %200) : (!llvm.ptr<3>, i32) -> ()
        %506 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
        %507 = "cute.add_offset"(%235, %506) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %508 = "builtin.unrealized_conversion_cast"(%507) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%508, %200) : (!llvm.ptr<3>, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.fence.mbarrier.init"() <{useIntrinsic = false}> : () -> ()
      "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
      %237 = "cute.recast_iter"(%222) : (!cute.ptr<i8, smem, align<64>>) -> !cute.ptr<i64, smem, align<64>>
      "scf.if"(%234) ({
        %498 = "builtin.unrealized_conversion_cast"(%237) : (!cute.ptr<i64, smem, align<64>>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%498, %200) : (!llvm.ptr<3>, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %238 = "cute.add_offset"(%237, %195) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      "scf.if"(%234) ({
        %497 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.init.shared"(%497, %201) : (!llvm.ptr<3>, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.fence.mbarrier.init"() <{useIntrinsic = false}> : () -> ()
      "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
      %239 = "cute.make_coord"(%218) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %240 = "cute.get_layout"(%arg5) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %241:2 = "cute.get_scalars"(%240) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> (i32, i32)
      %242 = "arith.ceildivsi"(%241#0, %201) : (i32, i32) -> i32
      %243 = "arith.ceildivsi"(%241#1, %191) : (i32, i32) -> i32
      %244 = "cute.make_shape"(%242, %243) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %245 = "cute.make_layout"(%244, %190) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,64),(?,?))">, !cute.stride<"((1@1,1@0),(128@1,64@0))">) -> !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %246:2 = "cute.get_scalars"(%245) <{only_dynamic}> : (!cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> (i32, i32)
      %247 = "cute.make_shape"(%246#1) : (i32) -> !cute.shape<"(128,64,?)">
      %248 = "cute.make_layout"(%247, %189) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,64,?)">, !cute.stride<"(1@1,1@0,64@0)">) -> !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %249 = "cute.crd2idx"(%239, %245) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %250 = "cute.get_iter"(%arg5) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.arith_tuple_iter<"(0,0)">
      %251 = "cute.add_offset"(%250, %249) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.arith_tuple_iter<"(0,?{div=128})">
      %252 = "cute.make_coord"(%219) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %253 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %254:2 = "cute.get_scalars"(%253) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(1@1,1@0)">) -> (i32, i32)
      %255 = "arith.ceildivsi"(%254#0, %188) : (i32, i32) -> i32
      %256 = "arith.ceildivsi"(%254#1, %191) : (i32, i32) -> i32
      %257 = "cute.make_shape"(%255, %256) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %258 = "cute.make_layout"(%257, %187) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((256,64),(?,?))">, !cute.stride<"((1@1,1@0),(256@1,64@0))">) -> !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %259:2 = "cute.get_scalars"(%258) <{only_dynamic}> : (!cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> (i32, i32)
      %260 = "cute.make_shape"(%259#1) : (i32) -> !cute.shape<"(256,64,?)">
      %261 = "cute.make_layout"(%260, %189) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(256,64,?)">, !cute.stride<"(1@1,1@0,64@0)">) -> !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %262 = "cute.crd2idx"(%252, %258) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %263 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">) -> !cute.arith_tuple_iter<"(0,0)">
      %264 = "cute.add_offset"(%263, %262) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.arith_tuple_iter<"(0,?{div=256})">
      %265 = "cute.make_coord"(%218, %219) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %266 = "cute.get_layout"(%arg8) : (!memref_gmem_f16_) -> !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %267:3 = "cute.get_scalars"(%266) <{only_dynamic}> : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> (i32, i32, i64)
      %268 = "arith.ceildivsi"(%267#0, %201) : (i32, i32) -> i32
      %269 = "arith.muli"(%267#2, %186) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %270 = "arith.ceildivsi"(%267#1, %188) : (i32, i32) -> i32
      %271 = "cute.make_shape"(%268, %270) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %272 = "cute.assume"(%267#2) : (i64) -> !cute.i64<divby 8192>
      %273 = "cute.assume"(%269) : (i64) -> !cute.i64<divby 1048576>
      %274 = "cute.make_stride"(%272, %273) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %275 = "cute.make_layout"(%271, %274) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,256),(?,?))">, !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %276:4 = "cute.get_scalars"(%275) <{only_dynamic}> : (!cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> (i32, i32, i64, i64)
      %277 = "cute.assume"(%276#2) : (i64) -> !cute.i64<divby 8192>
      %278 = "cute.make_stride"(%277) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %279 = "cute.make_layout"(%185, %278) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,256)">, !cute.stride<"(?{i64 div=8192},1)">) -> !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %280 = "cute.crd2idx"(%265, %275) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %281 = "cute.get_iter"(%arg8) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<32>>
      %282 = "cute.add_offset"(%281, %280) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %283 = "cute.get_scalars"(%248) <{only_dynamic}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> i32
      %284 = "cute.make_shape"(%283) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %285 = "cute.make_layout"(%284, %184) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,16),1,4,?)">, !cute.stride<"((1@1,1@0),0,16@0,64@0)">) -> !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %286 = "cute.get_scalars"(%261) <{only_dynamic}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> i32
      %287 = "cute.make_shape"(%286) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %288 = "cute.make_layout"(%287, %184) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((256,16),1,4,?)">, !cute.stride<"((1@1,1@0),0,16@0,64@0)">) -> !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %289 = "cute.get_scalars"(%279) <{only_dynamic}> : (!cute.layout<"(128,256):(?{i64 div=8192},1)">) -> i64
      %290 = "cute.assume"(%289) : (i64) -> !cute.i64<divby 8192>
      %291 = "cute.make_stride"(%290) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %292 = "cute.make_layout"(%183, %291) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,256),1,1)">, !cute.stride<"((?{i64 div=8192},1),0,0)">) -> !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %293 = "cute_nvgpu.make_umma_smem_desc"(%232) <{layout = #cute.layout<"((128,16),1,4,4):((64,1),0,16,8192)">, major = #cute_nvgpu.major<k>}> : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>) -> !cute_nvgpu.smem_desc
      %294 = "cute_nvgpu.make_umma_smem_desc"(%233) <{layout = #cute.layout<"((256,16),1,4,4):((64,1),0,16,16384)">, major = #cute_nvgpu.major<k>}> : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>) -> !cute_nvgpu.smem_desc
      %295 = "cute.get_scalars"(%285) <{only_dynamic}> : (!cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">) -> i32
      %296 = "cute.make_shape"(%295) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %297 = "cute.make_layout"(%296, %182) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((128,16),1,4),?)">, !cute.stride<"(((1@1,1@0),0,16@0),64@0)">) -> !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %298 = "cute.get_scalars"(%297) <{only_dynamic}> : (!cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">) -> i32
      %299 = "cute.make_shape"(%298) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %300 = "cute.make_layout"(%299, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((64,128),1),?)">, !cute.stride<"(((1@0,1@1),0),64@0)">) -> !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %301 = "cute.get_scalars"(%288) <{only_dynamic}> : (!cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">) -> i32
      %302 = "cute.make_shape"(%301) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %303 = "cute.make_layout"(%302, %182) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((256,16),1,4),?)">, !cute.stride<"(((1@1,1@0),0,16@0),64@0)">) -> !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %304 = "cute.get_scalars"(%303) <{only_dynamic}> : (!cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">) -> i32
      %305 = "cute.make_shape"(%304) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %306 = "cute.make_layout"(%305, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((64,256),1),?)">, !cute.stride<"(((1@0,1@1),0),64@0)">) -> !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      "llvm.inline_asm"(%200, %201) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %307 = "cute_nvgpu.arch.sm100.retrieve_tmem_ptr"(%224) : (!cute.ptr<i32, smem, align<16>>) -> !cute.ptr<f32, tmem, align<16>>
      %308 = "cute.get_scalars"(%292) <{only_dynamic}> : (!cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">) -> i64
      %309 = "cute.assume"(%308) : (i64) -> !cute.i64<divby 8192>
      %310 = "cute.make_stride"(%309) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %311 = "cute.make_layout"(%180, %310) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(((128,64)),((1,4),1,1))">, !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">) -> !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %312 = "arith.divsi"(%206, %205) : (i32, i32) -> i32
      %313 = "arith.muli"(%312, %179) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %314 = "cute.assume"(%313) : (i32) -> !cute.i32<divby 2097152>
      %315 = "cute.make_int_tuple"(%314) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %316 = "cute.add_offset"(%307, %315) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %317 = "cute.get_scalars"(%311) <{only_dynamic}> : (!cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">) -> i64
      %318 = "arith.muli"(%317, %178) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %319 = "arith.remsi"(%206, %205) : (i32, i32) -> i32
      %320 = "arith.extsi"(%319) : (i32) -> i64
      %321 = "arith.muli"(%320, %317) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %322 = "arith.extsi"(%312) : (i32) -> i64
      %323 = "arith.muli"(%322, %318) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %324 = "arith.addi"(%321, %323) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %325 = "cute.assume"(%324) : (i64) -> !cute.i64<divby 8192>
      %326 = "cute.make_int_tuple"(%325) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %327 = "cute.add_offset"(%282, %326) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %328 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %329 = "cute.memref.alloca"() : () -> !memref_rmem_f16_
      %330 = "cute.size"(%248) <{mode = array<i32: 2>}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %331 = "cute.get_leaves"(%330) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %332 = "cute.get_scalars"(%331) : (!cute.int_tuple<"?">) -> i32
      "scf.if"(%234) ({
        %354 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
        "nvvm.mbarrier.try_wait.parity.shared"(%354, %200, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
        %355 = "cute_nvgpu.atom.make_exec_tma"(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, tma_format = F16_RN>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
        %356 = "cute_nvgpu.atom.make_exec_tma"(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, tma_format = F16_RN>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
        %357 = "arith.minsi"(%332, %174) : (i32, i32) -> i32
        %358 = "cute_nvgpu.atom.get_value"(%355) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> i64
        %359 = "cute_nvgpu.atom.get_value"(%356) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> i64
        %360:3 = "scf.for"(%197, %357, %200, %197, %200, %197) ({
        ^bb0(%arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32):
          %457 = "cute.make_int_tuple"(%arg20) : (i32) -> !cute.int_tuple<"?">
          %458 = "cute.add_offset"(%236, %457) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %459 = "builtin.unrealized_conversion_cast"(%458) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
          "nvvm.mbarrier.try_wait.parity.shared"(%459, %arg21, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
          %460 = "nvvm.elect.sync"() : () -> i1
          "scf.if"(%460) ({
            %495 = "cute.add_offset"(%235, %457) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %496 = "builtin.unrealized_conversion_cast"(%495) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
            "nvvm.mbarrier.txn"(%496, %173) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %461 = "arith.addi"(%arg20, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %462 = "arith.addi"(%arg22, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %463 = "arith.cmpi"(%461, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %464 = "arith.select"(%463, %197, %461) : (i1, i32, i32) -> i32
          %465 = "scf.if"(%463) ({
            %494 = "arith.xori"(%arg21, %200) : (i32, i32) -> i32
            "scf.yield"(%494) : (i32) -> ()
          }, {
            "scf.yield"(%arg21) : (i32) -> ()
          }) : (i1) -> i32
          %466 = "cute.make_coord"(%arg22) : (i32) -> !cute.coord<"(_,?)">
          %467 = "cute.crd2idx"(%466, %300) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %468 = "cute.add_offset"(%251, %467) : (!cute.arith_tuple_iter<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
          %469 = "cute.deref_arith_tuple_iter"(%468) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %470:2 = "cute.get_leaves"(%469) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">)
          %471 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,?)">
          %472 = "cute.crd2idx"(%471, %172) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %473 = "cute.add_offset"(%232, %472) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %474 = "cute.add_offset"(%235, %457) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %475 = "cute.make_int_tuple"(%470#0, %470#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %476 = "cute.make_arith_tuple_iter"(%475) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
          %477 = "cute_nvgpu.atom.set_value"(%355, %474) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
          %478 = "builtin.unrealized_conversion_cast"(%474) : (!cute.ptr<i64, smem>) -> !cute.ptr<smem, align<8>>
          %479 = "cute_nvgpu.get_tma_desc_addr"(%477) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %480 = "cute.deref_arith_tuple_iter"(%476) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %481:2 = "cute.get_scalars"(%480) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (i32, i32)
          "cute_nvgpu.arch.copy.SM100.tma_load"(%479, %473, %478, %481#0, %481#1, %358) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
          %482 = "cute.crd2idx"(%466, %306) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %483 = "cute.add_offset"(%264, %482) : (!cute.arith_tuple_iter<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
          %484 = "cute.deref_arith_tuple_iter"(%483) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %485:2 = "cute.get_leaves"(%484) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">)
          %486 = "cute.crd2idx"(%471, %171) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
          %487 = "cute.add_offset"(%233, %486) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %488 = "cute.make_int_tuple"(%485#0, %485#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %489 = "cute.make_arith_tuple_iter"(%488) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
          %490 = "cute_nvgpu.atom.set_value"(%356, %474) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
          %491 = "cute_nvgpu.get_tma_desc_addr"(%490) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %492 = "cute.deref_arith_tuple_iter"(%489) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %493:2 = "cute.get_scalars"(%492) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (i32, i32)
          "cute_nvgpu.arch.copy.SM100.tma_load"(%491, %487, %478, %493#0, %493#1, %359) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
          "scf.yield"(%464, %465, %462) : (i32, i32, i32) -> ()
        }) : (i32, i32, i32, i32, i32, i32) -> (i32, i32, i32)
        %361:7 = "scf.for"(%197, %332, %200, %360#2, %360#0, %360#1, %197, %197, %197, %161) ({
        ^bb0(%arg11: i32, %arg12: i32, %arg13: i32, %arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: !llvm.struct<(i1, i1, i1)>):
          %365 = "builtin.unrealized_conversion_cast"(%arg18) : (!llvm.struct<(i1, i1, i1)>) -> !mma_f16_f16_f32_128x256x16_
          %366 = "arith.addi"(%arg11, %357) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %367 = "arith.cmpi"(%366, %332) <{predicate = 6 : i64}> : (i32, i32) -> i1
          %368:3 = "scf.if"(%367) ({
            %415 = "cute.make_int_tuple"(%arg13) : (i32) -> !cute.int_tuple<"?">
            %416 = "cute.add_offset"(%236, %415) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %417 = "builtin.unrealized_conversion_cast"(%416) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
            "nvvm.mbarrier.try_wait.parity.shared"(%417, %arg14, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
            %418 = "nvvm.elect.sync"() : () -> i1
            "scf.if"(%418) ({
              %455 = "cute.add_offset"(%235, %415) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %456 = "builtin.unrealized_conversion_cast"(%455) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
              "nvvm.mbarrier.txn"(%456, %173) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
              "scf.yield"() : () -> ()
            }, {
            }) : (i1) -> ()
            %419 = "arith.addi"(%arg13, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %420 = "arith.addi"(%arg12, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %421 = "arith.cmpi"(%419, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
            %422 = "arith.select"(%421, %197, %419) : (i1, i32, i32) -> i32
            %423 = "scf.if"(%421) ({
              %454 = "arith.xori"(%arg14, %200) : (i32, i32) -> i32
              "scf.yield"(%454) : (i32) -> ()
            }, {
              "scf.yield"(%arg14) : (i32) -> ()
            }) : (i1) -> i32
            %424 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"(_,?)">
            %425 = "cute.crd2idx"(%424, %300) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %426 = "cute.add_offset"(%251, %425) : (!cute.arith_tuple_iter<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
            %427 = "cute.deref_arith_tuple_iter"(%426) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %428:2 = "cute.get_leaves"(%427) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">)
            %429 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"(_,?)">
            %430 = "cute.crd2idx"(%429, %172) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %431 = "cute.add_offset"(%232, %430) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %432 = "cute.add_offset"(%235, %415) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %433 = "cute.make_int_tuple"(%428#0, %428#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %434 = "cute.make_arith_tuple_iter"(%433) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=128})">
            %435 = "cute_nvgpu.atom.set_value"(%355, %432) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
            %436 = "builtin.unrealized_conversion_cast"(%432) : (!cute.ptr<i64, smem>) -> !cute.ptr<smem, align<8>>
            %437 = "cute_nvgpu.atom.get_value"(%355) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> i64
            %438 = "cute_nvgpu.get_tma_desc_addr"(%435) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %439 = "cute.deref_arith_tuple_iter"(%434) : (!cute.arith_tuple_iter<"(?{div=64},?{div=128})">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %440:2 = "cute.get_scalars"(%439) : (!cute.int_tuple<"(?{div=64},?{div=128})">) -> (i32, i32)
            "cute_nvgpu.arch.copy.SM100.tma_load"(%438, %431, %436, %440#0, %440#1, %437) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
            %441 = "cute.crd2idx"(%424, %306) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %442 = "cute.add_offset"(%264, %441) : (!cute.arith_tuple_iter<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
            %443 = "cute.deref_arith_tuple_iter"(%442) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %444:2 = "cute.get_leaves"(%443) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">)
            %445 = "cute.crd2idx"(%429, %171) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
            %446 = "cute.add_offset"(%233, %445) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %447 = "cute.make_int_tuple"(%444#0, %444#1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %448 = "cute.make_arith_tuple_iter"(%447) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=256})">
            %449 = "cute_nvgpu.atom.set_value"(%356, %432) <{field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>, !cute.ptr<i64, smem>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
            %450 = "cute_nvgpu.atom.get_value"(%356) <{field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>}> : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> i64
            %451 = "cute_nvgpu.get_tma_desc_addr"(%449) : (!cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %452 = "cute.deref_arith_tuple_iter"(%448) : (!cute.arith_tuple_iter<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %453:2 = "cute.get_scalars"(%452) : (!cute.int_tuple<"(?{div=64},?{div=256})">) -> (i32, i32)
            "cute_nvgpu.arch.copy.SM100.tma_load"(%451, %446, %436, %453#0, %453#1, %450) <{mode = #cute_nvgpu.tma_load_mode<tiled>, num_cta = 1 : i32, operandSegmentSizes = array<i32: 1, 1, 1, 2, 0, 0, 1>}> : (!cute.ptr<generic, align<64>>, !cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.ptr<smem, align<8>>, i32, i32, i64) -> ()
            "scf.yield"(%422, %423, %420) : (i32, i32, i32) -> ()
          }, {
            "scf.yield"(%arg13, %arg14, %arg12) : (i32, i32, i32) -> ()
          }) : (i1) -> (i32, i32, i32)
          %369 = "cute.make_int_tuple"(%arg16) : (i32) -> !cute.int_tuple<"?">
          %370 = "cute.add_offset"(%235, %369) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %371 = "builtin.unrealized_conversion_cast"(%370) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
          "nvvm.mbarrier.try_wait.parity.shared"(%371, %arg17, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
          %372 = "arith.addi"(%arg16, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %373 = "arith.addi"(%arg15, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %374 = "arith.cmpi"(%372, %175) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %375 = "arith.select"(%374, %197, %372) : (i1, i32, i32) -> i32
          %376 = "scf.if"(%374) ({
            %414 = "arith.xori"(%arg17, %200) : (i32, i32) -> i32
            "scf.yield"(%414) : (i32) -> ()
          }, {
            "scf.yield"(%arg17) : (i32) -> ()
          }) : (i1) -> i32
          %377 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,0,?)">
          %378 = "cute.crd2idx"(%377, %170) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %379 = "cute.add_offset"(%293, %378) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
          %380 = "cute.crd2idx"(%377, %169) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %381 = "cute.add_offset"(%294, %380) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
          %382 = "cute_nvgpu.atom.get_value"(%365) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_a>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
          %383 = "cute_nvgpu.atom.get_value"(%365) <{field = #cute_nvgpu.atom_mma_field_sm100<neg_b>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
          %384 = "cute_nvgpu.atom.get_value"(%365) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_) -> i1
          %385 = "arith.extui"(%382) : (i1) -> i32
          %386 = "arith.extui"(%383) : (i1) -> i32
          %387 = "arith.shli"(%385, %167) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %388 = "arith.shli"(%386, %166) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %389 = "arith.ori"(%387, %168) : (i32, i32) -> i32
          %390 = "arith.ori"(%389, %388) : (i32, i32) -> i32
          "cute_nvgpu.arch.mma.SM100.umma"(%379, %381, %307, %390, %384) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
          %391 = "cute_nvgpu.atom.set_value"(%365, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
          %392 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,1,?)">
          %393 = "cute.crd2idx"(%392, %170) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %394 = "cute.add_offset"(%293, %393) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %395 = "cute.crd2idx"(%392, %169) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %396 = "cute.add_offset"(%294, %395) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          "cute_nvgpu.arch.mma.SM100.umma"(%394, %396, %307, %390, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
          %397 = "cute_nvgpu.atom.set_value"(%391, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
          %398 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,2,?)">
          %399 = "cute.crd2idx"(%398, %170) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
          %400 = "cute.add_offset"(%293, %399) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %401 = "cute.crd2idx"(%398, %169) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
          %402 = "cute.add_offset"(%294, %401) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          "cute_nvgpu.arch.mma.SM100.umma"(%400, %402, %307, %390, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
          %403 = "cute_nvgpu.atom.set_value"(%397, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
          %404 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,3,?)">
          %405 = "cute.crd2idx"(%404, %170) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %406 = "cute.add_offset"(%293, %405) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %407 = "cute.crd2idx"(%404, %169) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %408 = "cute.add_offset"(%294, %407) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          "cute_nvgpu.arch.mma.SM100.umma"(%406, %408, %307, %390, %177) <{a_type = f16, num_cta = 1 : i32, scale = 0 : i32}> : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
          %409 = "cute_nvgpu.atom.set_value"(%403, %177) <{field = #cute_nvgpu.atom_mma_field_sm100<accum_c>}> : (!mma_f16_f16_f32_128x256x16_, i1) -> !mma_f16_f16_f32_128x256x16_
          %410 = "builtin.unrealized_conversion_cast"(%409) : (!mma_f16_f16_f32_128x256x16_) -> !llvm.struct<(i1, i1, i1)>
          %411 = "nvvm.elect.sync"() : () -> i1
          "scf.if"(%411) ({
            %412 = "cute.add_offset"(%236, %369) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %413 = "builtin.unrealized_conversion_cast"(%412) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
            "nvvm.tcgen05.commit.arrive"(%413) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"(%368#2, %368#0, %368#1, %373, %375, %376, %410) : (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> ()
        }) : (i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
        %362 = "nvvm.elect.sync"() : () -> i1
        "scf.if"(%362) ({
          %363 = "cute.derefine"(%237) : (!cute.ptr<i64, smem, align<64>>) -> !cute.ptr<i64, smem>
          %364 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
          "nvvm.tcgen05.commit.arrive"(%364) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "scf.if"(%234) ({
        "cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit"() : () -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %333 = "cute.derefine"(%237) : (!cute.ptr<i64, smem, align<64>>) -> !cute.ptr<i64, smem>
      %334 = "builtin.unrealized_conversion_cast"(%333) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.try_wait.parity.shared"(%334, %197, %176) <{useIntrinsic = false}> : (!llvm.ptr<3>, i32, i32) -> ()
      %335 = "cute.get_iter"(%328) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %336 = "builtin.unrealized_conversion_cast"(%335) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %337 = "cute.get_iter"(%329) : (!memref_rmem_f16_) -> !cute.ptr<f16, rmem, align<32>>
      "scf.for"(%197, %175, %200) ({
      ^bb0(%arg9: i32):
        %339 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"(_,_,?)">
        %340 = "cute.crd2idx"(%339, %165) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %341 = "cute.add_offset"(%316, %340) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        %342 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%341) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
        "llvm.store"(%342, %336) <{ordering = 0 : i64}> : (vector<64xi32>, !llvm.ptr) -> ()
        %343 = "cute.memref.load_vec"(%328) : (!memref_rmem_f32_) -> vector<64xf32>
        %344 = "arith.truncf"(%343) : (vector<64xf32>) -> vector<64xf16>
        "cute.memref.store_vec"(%344, %329) : (vector<64xf16>, !memref_rmem_f16_) -> ()
        %345 = "cute.crd2idx"(%339, %164) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %346 = "cute.add_offset"(%327, %345) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        "scf.for"(%197, %175, %200) ({
        ^bb0(%arg10: i32):
          %347 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
          %348 = "cute.crd2idx"(%347, %163) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %349 = "cute.add_offset"(%337, %348) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
          %350 = "cute.add_offset"(%346, %348) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
          %351 = "builtin.unrealized_conversion_cast"(%349) : (!cute.ptr<f16, rmem, align<32>>) -> !llvm.ptr
          %352 = "builtin.unrealized_conversion_cast"(%350) : (!cute.ptr<f16, gmem, align<32>>) -> !llvm.ptr<1>
          %353 = "llvm.load"(%351) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<16xf16>
          "llvm.store"(%353, %352) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<16xf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %338 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<i64, smem>) -> !llvm.ptr<3>
      "nvvm.mbarrier.txn"(%338, %200) <{kind = #nvvm.mbar_txn_kind<arrive>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
      "llvm.inline_asm"(%200) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "scf.if"(%234) ({
        "cute_nvgpu.arch.sm100.dealloc_tmem"(%307, %196) : (!cute.ptr<f32, tmem, align<16>>, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
