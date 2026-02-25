!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>, layout_copy_tv = <"(256,4):(4,1)">, tiler_mn = <"[128:1;8:1]">>
!copy_ldgsts1 = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>, layout_copy_tv = <"((8,32),1):((32,1),0)">, tiler_mn = <"[32:1;8:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "(256,64):(1,256)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "(?,?{div=64}):(?{i64 div=64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, align<16>, "(?,?{div=256}):(?{i64 div=256},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, "(1,(4,2),8):(0,(1,4),8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, "(1):(0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,1)">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,1)">
!memref_rmem_i8_4 = !cute.memref<i8, rmem, align<32>, "(1):(1)">
!memref_rmem_i8_5 = !cute.memref<i8, rmem, "(1):(1)">
!memref_rmem_i8_6 = !cute.memref<i8, rmem, align<32>, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_smem_f32_ = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),128)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),132)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> (), sym_name = "kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_1, %arg6: !memref_gmem_f32_2):
      %61 = "arith.constant"() <{value = dense<0.000000e+00> : vector<64xf32>}> : () -> vector<64xf32>
      %62 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %63 = "cute.static"() : () -> !cute.shape<"(1,(((4,2),(4,2))))">
      %64 = "cute.static"() : () -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">
      %65 = "cute.static"() : () -> !cute.shape<"(1,((4,2),(4,2)))">
      %66 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">
      %67 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %68 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %69 = "cute.static"() : () -> !cute.layout<"(1,(4,2),1):(0,(1,4),0)">
      %70 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %71 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),132)">
      %72 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
      %73 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),128)">
      %74 = "arith.constant"() <{value = 7 : i32}> : () -> i32
      %75 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
      %76 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
      %77 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">
      %78 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">
      %79 = "cute.static"() : () -> !cute.shape<"(1,(4,2),(4,2))">
      %80 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %81 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %82 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %83 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,0)))">
      %84 = "cute.static"() : () -> !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">
      %85 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">
      %86 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %87 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,1)))">
      %88 = "cute.static"() : () -> !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
      %89 = "cute.static"() : () -> !cute.shape<"((1,1),((4,1)))">
      %90 = "cute.static"() : () -> !cute.shape<"((1,1),(4,1))">
      %91 = "cute.static"() : () -> !cute.shape<"((1,1),4,1)">
      %92 = "cute.static"() : () -> !cute.layout<"(1):(1)">
      %93 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
      %94 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %95 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %96 = "cute.static"() : () -> !cute.stride<"((0,0),32@0,0,8@1)">
      %97 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %98 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,8@1)">
      %99 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(128@0,8@1))">
      %100 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">
      %101 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %102 = "arith.constant"() <{value = 132 : i32}> : () -> i32
      %103 = "arith.constant"() <{value = 32 : i64}> : () -> i64
      %104 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %105 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %106 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %107 = "cute.static"() : () -> !cute.int_tuple<"12288">
      %108 = "cute.static"() : () -> !cute.shape<"(128,128)">
      %109 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %110 = "arith.constant"() <{value = 128 : i64}> : () -> i64
      %111 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %112 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">
      %113 = "cute.static"() : () -> !cute.layout<"1:0">
      %114 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %115 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %116 = "nvvm.read.ptx.sreg.ctaid.y"() <{range = #llvm.constant_range<i32, 0, 65535>}> : () -> i32
      %117 = "cute.make_coord"(%115) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %118 = "cute.crd2idx"(%117, %112) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">) -> !cute.int_tuple<"?{div=128}">
      %119 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %120 = "cute.add_offset"(%119, %118) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %121 = "cute.make_coord"(%116) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %122 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %123:3 = "cute.get_scalars"(%122) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> (i32, i32, i64)
      %124 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %125 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %126 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %127 = "arith.cmpi"(%111, %125) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %128 = "arith.select"(%127, %126, %124) : (i1, i32, i32) -> i32
      %129 = "arith.addi"(%128, %123#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %130 = "arith.divsi"(%129, %111) : (i32, i32) -> i32
      %131 = "arith.addi"(%124, %130) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %132 = "arith.subi"(%125, %123#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %133 = "arith.divsi"(%132, %111) : (i32, i32) -> i32
      %134 = "arith.subi"(%125, %133) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %135 = "arith.cmpi"(%123#0, %125) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %136 = "arith.cmpi"(%123#0, %125) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %137 = "arith.cmpi"(%111, %125) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %138 = "arith.cmpi"(%111, %125) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %139 = "arith.andi"(%135, %137) : (i1, i1) -> i1
      %140 = "arith.andi"(%136, %138) : (i1, i1) -> i1
      %141 = "arith.ori"(%139, %140) : (i1, i1) -> i1
      %142 = "arith.select"(%141, %131, %134) : (i1, i32, i32) -> i32
      %143 = "arith.muli"(%123#2, %110) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %144 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %145 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %146 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %147 = "arith.cmpi"(%109, %145) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %148 = "arith.select"(%147, %146, %144) : (i1, i32, i32) -> i32
      %149 = "arith.addi"(%148, %123#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %150 = "arith.divsi"(%149, %109) : (i32, i32) -> i32
      %151 = "arith.addi"(%144, %150) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %152 = "arith.subi"(%145, %123#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %153 = "arith.divsi"(%152, %109) : (i32, i32) -> i32
      %154 = "arith.subi"(%145, %153) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %155 = "arith.cmpi"(%123#1, %145) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %156 = "arith.cmpi"(%123#1, %145) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %157 = "arith.cmpi"(%109, %145) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %158 = "arith.cmpi"(%109, %145) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %159 = "arith.andi"(%155, %157) : (i1, i1) -> i1
      %160 = "arith.andi"(%156, %158) : (i1, i1) -> i1
      %161 = "arith.ori"(%159, %160) : (i1, i1) -> i1
      %162 = "arith.select"(%161, %151, %154) : (i1, i32, i32) -> i32
      %163 = "cute.make_shape"(%142, %162) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %164 = "cute.assume"(%123#2) : (i64) -> !cute.i64<divby 64>
      %165 = "cute.assume"(%143) : (i64) -> !cute.i64<divby 8192>
      %166 = "cute.make_stride"(%164, %165) : (!cute.i64<divby 64>, !cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">
      %167 = "cute.make_layout"(%163, %166) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">
      %168:4 = "cute.get_scalars"(%167) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> (i32, i32, i64, i64)
      %169 = "cute.make_shape"(%168#1) : (i32) -> !cute.shape<"(128,8,?)">
      %170 = "cute.assume"(%168#2) : (i64) -> !cute.i64<divby 64>
      %171 = "cute.make_stride"(%170) : (!cute.i64<divby 64>) -> !cute.stride<"(?{i64 div=64},1,8)">
      %172 = "cute.make_layout"(%169, %171) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(?{i64 div=64},1,8)">) -> !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %173 = "cute.crd2idx"(%121, %167) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.int_tuple<"?{i64 div=8192}">
      %174 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem, align<16>>
      %175 = "cute.add_offset"(%174, %173) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f32, gmem, align<16>>
      %176 = "cute.make_coord"(%115, %116) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %177 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %178:3 = "cute.get_scalars"(%177) <{only_dynamic}> : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> (i32, i32, i64)
      %179 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %180 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %181 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %182 = "arith.cmpi"(%111, %180) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %183 = "arith.select"(%182, %181, %179) : (i1, i32, i32) -> i32
      %184 = "arith.addi"(%183, %178#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %185 = "arith.divsi"(%184, %111) : (i32, i32) -> i32
      %186 = "arith.addi"(%179, %185) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %187 = "arith.subi"(%180, %178#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %188 = "arith.divsi"(%187, %111) : (i32, i32) -> i32
      %189 = "arith.subi"(%180, %188) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %190 = "arith.cmpi"(%178#0, %180) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %191 = "arith.cmpi"(%178#0, %180) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %192 = "arith.cmpi"(%111, %180) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %193 = "arith.cmpi"(%111, %180) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %194 = "arith.andi"(%190, %192) : (i1, i1) -> i1
      %195 = "arith.andi"(%191, %193) : (i1, i1) -> i1
      %196 = "arith.ori"(%194, %195) : (i1, i1) -> i1
      %197 = "arith.select"(%196, %186, %189) : (i1, i32, i32) -> i32
      %198 = "arith.muli"(%178#2, %110) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %199 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %200 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %201 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %202 = "arith.cmpi"(%111, %200) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %203 = "arith.select"(%202, %201, %199) : (i1, i32, i32) -> i32
      %204 = "arith.addi"(%203, %178#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %205 = "arith.divsi"(%204, %111) : (i32, i32) -> i32
      %206 = "arith.addi"(%199, %205) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %207 = "arith.subi"(%200, %178#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %208 = "arith.divsi"(%207, %111) : (i32, i32) -> i32
      %209 = "arith.subi"(%200, %208) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %210 = "arith.cmpi"(%178#1, %200) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %211 = "arith.cmpi"(%178#1, %200) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %212 = "arith.cmpi"(%111, %200) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %213 = "arith.cmpi"(%111, %200) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %214 = "arith.andi"(%210, %212) : (i1, i1) -> i1
      %215 = "arith.andi"(%211, %213) : (i1, i1) -> i1
      %216 = "arith.ori"(%214, %215) : (i1, i1) -> i1
      %217 = "arith.select"(%216, %206, %209) : (i1, i32, i32) -> i32
      %218 = "cute.make_shape"(%197, %217) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %219 = "cute.assume"(%178#2) : (i64) -> !cute.i64<divby 256>
      %220 = "cute.assume"(%198) : (i64) -> !cute.i64<divby 32768>
      %221 = "cute.make_stride"(%219, %220) : (!cute.i64<divby 256>, !cute.i64<divby 32768>) -> !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">
      %222 = "cute.make_layout"(%218, %221) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,128),(?,?))">, !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">
      %223:4 = "cute.get_scalars"(%222) <{only_dynamic}> : (!cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> (i32, i32, i64, i64)
      %224 = "cute.assume"(%223#2) : (i64) -> !cute.i64<divby 256>
      %225 = "cute.make_stride"(%224) : (!cute.i64<divby 256>) -> !cute.stride<"(?{i64 div=256},1)">
      %226 = "cute.make_layout"(%108, %225) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,128)">, !cute.stride<"(?{i64 div=256},1)">) -> !cute.layout<"(128,128):(?{i64 div=256},1)">
      %227 = "cute.crd2idx"(%176, %222) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.int_tuple<"?{i64 div=128}">
      %228 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem, align<16>>
      %229 = "cute.add_offset"(%228, %227) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %230 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %231 = "cute.add_offset"(%230, %107) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"12288">) -> !cute.ptr<i8, smem, align<1024>>
      %232 = "cute.recast_iter"(%230) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %233 = "cute.recast_iter"(%231) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %234 = "arith.divsi"(%114, %106) : (i32, i32) -> i32
      %235 = "arith.remsi"(%114, %106) : (i32, i32) -> i32
      %236 = "arith.muli"(%235, %105) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %237 = "arith.muli"(%234, %104) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %238 = "arith.addi"(%236, %237) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %239 = "cute.assume"(%238) : (i32) -> !cute.i32<divby 4>
      %240 = "cute.make_int_tuple"(%239) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %241 = "cute.add_offset"(%120, %240) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %242 = "arith.muli"(%114, %105) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %243 = "cute.assume"(%242) : (i32) -> !cute.i32<divby 4>
      %244 = "cute.make_int_tuple"(%243) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %245 = "cute.add_offset"(%232, %244) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %246:2 = "cute.get_scalars"(%172) <{only_dynamic}> : (!cute.layout<"(128,8,?):(?{i64 div=64},1,8)">) -> (i32, i64)
      %247 = "arith.muli"(%246#1, %103) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %248 = "arith.divsi"(%114, %109) : (i32, i32) -> i32
      %249 = "arith.remsi"(%114, %109) : (i32, i32) -> i32
      %250 = "arith.extsi"(%248) : (i32) -> i64
      %251 = "arith.muli"(%250, %246#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %252 = "arith.extsi"(%249) : (i32) -> i64
      %253 = "arith.addi"(%252, %251) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %254 = "cute.make_int_tuple"(%253) : (i64) -> !cute.int_tuple<"?{i64}">
      %255 = "cute.add_offset"(%175, %254) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %256 = "cute.make_shape"(%246#0) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %257 = "cute.assume"(%247) : (i64) -> !cute.i64<divby 2048>
      %258 = "cute.make_stride"(%257) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0,8)">
      %259 = "cute.make_layout"(%256, %258) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),?{i64 div=2048},0,8)">) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %260 = "arith.muli"(%249, %102) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %261 = "arith.addi"(%260, %248) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %262 = "cute.make_int_tuple"(%261) : (i32) -> !cute.int_tuple<"?">
      %263 = "cute.add_offset"(%233, %262) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<f32, smem>
      %264 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %265 = "cute.get_shape"(%122) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
      %266:2 = "cute.get_leaves"(%265) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
      %267 = "cute.to_int_tuple"(%266#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %268 = "cute.to_int_tuple"(%266#1) : (!cute.shape<"?{div=64}">) -> !cute.int_tuple<"?{div=64}">
      %269 = "cute.make_shape"(%267, %268) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=64}">) -> !cute.shape<"(?,?{div=64})">
      %270 = "cute.make_layout"(%269, %101) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=64})">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %271 = "cute.crd2idx"(%117, %100) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %272 = "cute.add_offset"(%264, %271) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %273 = "cute.deref_arith_tuple_iter"(%272) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %274:2 = "cute.get_leaves"(%273) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %275:2 = "cute.get_scalars"(%270) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(1@0,1@1)">) -> (i32, i32)
      %276 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %277 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %278 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %279 = "arith.cmpi"(%111, %277) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %280 = "arith.select"(%279, %278, %276) : (i1, i32, i32) -> i32
      %281 = "arith.addi"(%280, %275#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %282 = "arith.divsi"(%281, %111) : (i32, i32) -> i32
      %283 = "arith.addi"(%276, %282) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %284 = "arith.subi"(%277, %275#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %285 = "arith.divsi"(%284, %111) : (i32, i32) -> i32
      %286 = "arith.subi"(%277, %285) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %287 = "arith.cmpi"(%275#0, %277) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %288 = "arith.cmpi"(%275#0, %277) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %289 = "arith.cmpi"(%111, %277) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %290 = "arith.cmpi"(%111, %277) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %291 = "arith.andi"(%287, %289) : (i1, i1) -> i1
      %292 = "arith.andi"(%288, %290) : (i1, i1) -> i1
      %293 = "arith.ori"(%291, %292) : (i1, i1) -> i1
      %294 = "arith.select"(%293, %283, %286) : (i1, i32, i32) -> i32
      %295 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %296 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %297 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %298 = "arith.cmpi"(%109, %296) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %299 = "arith.select"(%298, %297, %295) : (i1, i32, i32) -> i32
      %300 = "arith.addi"(%299, %275#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %301 = "arith.divsi"(%300, %109) : (i32, i32) -> i32
      %302 = "arith.addi"(%295, %301) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %303 = "arith.subi"(%296, %275#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %304 = "arith.divsi"(%303, %109) : (i32, i32) -> i32
      %305 = "arith.subi"(%296, %304) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %306 = "arith.cmpi"(%275#1, %296) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %307 = "arith.cmpi"(%275#1, %296) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %308 = "arith.cmpi"(%109, %296) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %309 = "arith.cmpi"(%109, %296) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %310 = "arith.andi"(%306, %308) : (i1, i1) -> i1
      %311 = "arith.andi"(%307, %309) : (i1, i1) -> i1
      %312 = "arith.ori"(%310, %311) : (i1, i1) -> i1
      %313 = "arith.select"(%312, %302, %305) : (i1, i32, i32) -> i32
      %314 = "cute.make_shape"(%294, %313) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %315 = "cute.make_layout"(%314, %99) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((1@0,1@1),(128@0,8@1))">) -> !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">
      %316:2 = "cute.get_scalars"(%315) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> (i32, i32)
      %317 = "cute.make_shape"(%316#1) : (i32) -> !cute.shape<"(128,8,?)">
      %318 = "cute.make_layout"(%317, %98) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(1@0,1@1,8@1)">) -> !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %319 = "cute.crd2idx"(%121, %315) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %320 = "cute.add_offset"(%264, %319) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %321 = "cute.deref_arith_tuple_iter"(%320) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %322:2 = "cute.get_leaves"(%321) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %323 = "cute.make_int_tuple"(%274#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %324 = "cute.tuple_add"(%323, %97) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %325:2 = "cute.get_leaves"(%324) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %326 = "cute.make_int_tuple"(%325#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %327 = "cute.make_arith_tuple_iter"(%326) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %328 = "cute.make_int_tuple"(%322#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %329 = "cute.tuple_add"(%328, %97) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %330:2 = "cute.get_leaves"(%329) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %331 = "cute.make_int_tuple"(%330#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %332 = "cute.make_arith_tuple_iter"(%331) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %333 = "cute.assume"(%236) : (i32) -> !cute.i32<divby 4>
      %334 = "cute.make_int_tuple"(%333, %234) : (!cute.i32<divby 4>, i32) -> !cute.int_tuple<"(?{div=4},?)">
      %335 = "cute.add_offset"(%327, %334) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?{div=4},?)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
      %336 = "cute.get_scalars"(%318) <{only_dynamic}> : (!cute.layout<"(128,8,?):(1@0,1@1,8@1)">) -> i32
      %337 = "cute.make_int_tuple"(%248, %249) : (i32, i32) -> !cute.int_tuple<"(?,?)">
      %338 = "cute.add_offset"(%332, %337) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %339 = "cute.make_shape"(%336) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %340 = "cute.make_layout"(%339, %96) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),32@0,0,8@1)">) -> !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
      %341 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %342 = "cute.memref.alloca"() : () -> !memref_rmem_i8_1
      %343 = "cute.memref.alloca"() : () -> !memref_rmem_i8_2
      %344 = "cute.memref.alloca"() : () -> !memref_rmem_i8_3
      %345 = "cute.deref_arith_tuple_iter"(%335) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
      %346:2 = "cute.get_leaves"(%345) : (!cute.int_tuple<"(?{div=4},?)">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %347 = "cute.make_coord"(%346#0) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"?{div=4}">
      %348 = "cute.get_scalars"(%347) : (!cute.coord<"?{div=4}">) -> i32
      %349 = "arith.cmpi"(%348, %104) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %350 = "arith.extui"(%349) : (i1) -> i8
      %351 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      %352 = "cute.derefine"(%351) : (!cute.coord<"(0,0,0)">) -> !cute.coord<"(?,?,0)">
      "cute.memref.store"(%341, %352, %350) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %353 = "cute.get_iter"(%341) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %354 = "cute.make_coord"(%267) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %355 = "cute.get_scalars"(%354) : (!cute.coord<"?">) -> i32
      "cf.br"(%95)[^bb1] : (i32) -> ()
    ^bb1(%356: i32):  // 2 preds: ^bb0, ^bb2
      %357 = "arith.cmpi"(%356, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%357)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb2:  // pred: ^bb1
      %358 = "cute.make_coord"(%356) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %359 = "cute.crd2idx"(%358, %340) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %360 = "cute.add_offset"(%338, %359) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
      %361 = "cute.deref_arith_tuple_iter"(%360) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %362:2 = "cute.get_leaves"(%361) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %363 = "cute.make_coord"(%362#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %364 = "cute.get_scalars"(%363) : (!cute.coord<"?">) -> i32
      %365 = "arith.cmpi"(%364, %355) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %366 = "arith.extui"(%365) : (i1) -> i8
      %367 = "cute.make_coord"(%356) : (i32) -> !cute.coord<"(0,?,0)">
      %368 = "cute.derefine"(%367) : (!cute.coord<"(0,?,0)">) -> !cute.coord<"(?,?,0)">
      "cute.memref.store"(%342, %368, %366) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
      %369 = "arith.addi"(%356, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%369)[^bb1] : (i32) -> ()
    ^bb3:  // pred: ^bb1
      %370 = "cute.get_iter"(%342) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %371 = "cute.make_coord"(%346#0) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},-1)">
      %372 = "cute.derefine"(%371) : (!cute.coord<"(?{div=4},-1)">) -> !cute.coord<"(?{div=4},?)">
      %373 = "cute.make_coord"(%346#1) : (!cute.int_tuple<"?">) -> !cute.coord<"(256,?)">
      %374:2 = "cute.get_scalars"(%372) : (!cute.coord<"(?{div=4},?)">) -> (i32, i32)
      %375:2 = "cute.get_scalars"(%373) : (!cute.coord<"(256,?)">) -> (i32, i32)
      %376 = "arith.cmpi"(%374#0, %104) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %377 = "arith.cmpi"(%374#1, %375#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %378 = "arith.andi"(%376, %377) : (i1, i1) -> i1
      %379 = "arith.extui"(%378) : (i1) -> i8
      %380 = "cute.derefine"(%351) : (!cute.coord<"(0,0,0)">) -> !cute.coord<"(?,?,?)">
      "cute.memref.store"(%343, %380, %379) : (!memref_rmem_i8_2, !cute.coord<"(?,?,?)">, i8) -> ()
      %381 = "cute.get_iter"(%343) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
      "cf.br"(%95)[^bb4] : (i32) -> ()
    ^bb4(%382: i32):  // 2 preds: ^bb3, ^bb5
      %383 = "arith.cmpi"(%382, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%383)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %384 = "cute.make_coord"(%382) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %385 = "cute.crd2idx"(%384, %340) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %386 = "cute.add_offset"(%338, %385) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
      %387 = "cute.deref_arith_tuple_iter"(%386) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %388:2 = "cute.get_leaves"(%387) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %389 = "cute.make_coord"(%388#0) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,-1)">
      %390 = "cute.derefine"(%389) : (!cute.coord<"(?,-1)">) -> !cute.coord<"(?,?)">
      %391 = "cute.make_coord"(%267, %388#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %392:2 = "cute.get_scalars"(%390) : (!cute.coord<"(?,?)">) -> (i32, i32)
      %393:2 = "cute.get_scalars"(%391) : (!cute.coord<"(?,?)">) -> (i32, i32)
      %394 = "arith.cmpi"(%392#0, %393#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %395 = "arith.cmpi"(%392#1, %393#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %396 = "arith.andi"(%394, %395) : (i1, i1) -> i1
      %397 = "arith.extui"(%396) : (i1) -> i8
      %398 = "cute.make_coord"(%382) : (i32) -> !cute.coord<"(0,?,0)">
      %399 = "cute.derefine"(%398) : (!cute.coord<"(0,?,0)">) -> !cute.coord<"(?,?,?)">
      "cute.memref.store"(%344, %399, %397) : (!memref_rmem_i8_3, !cute.coord<"(?,?,?)">, i8) -> ()
      %400 = "arith.addi"(%382, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%400)[^bb4] : (i32) -> ()
    ^bb6:  // pred: ^bb4
      %401 = "cute.get_iter"(%344) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
      %402 = "cute.make_view"(%381, %92) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1):(1)">) -> !memref_rmem_i8_4
      %403 = "cute.derefine"(%402) : (!memref_rmem_i8_4) -> !memref_rmem_i8_5
      %404 = "cute.get_iter"(%403) : (!memref_rmem_i8_5) -> !cute.ptr<i8, rmem>
      %405 = "builtin.unrealized_conversion_cast"(%404) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %406 = "llvm.load"(%405) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %407 = "llvm.trunc"(%406) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %408 = "cute.recast_iter"(%241) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %409 = "cute.recast_iter"(%245) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%409, %408, %407) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %410:2 = "cute.get_scalars"(%259) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
      %411 = "cute.assume"(%410#1) : (i64) -> !cute.i64<divby 2048>
      %412 = "cute.make_stride"(%411) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %413 = "cute.make_layout"(%91, %412) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %414 = "cute.append_to_rank"(%413, %113) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %415 = "cute.get_scalars"(%414) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
      %416 = "cute.assume"(%415) : (i64) -> !cute.i64<divby 2048>
      %417 = "cute.make_stride"(%416) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %418 = "cute.make_layout"(%90, %417) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %419 = "cute.append_to_rank"(%418, %113) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %420 = "cute.get_scalars"(%419) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
      %421 = "cute.assume"(%420) : (i64) -> !cute.i64<divby 2048>
      %422 = "cute.make_stride"(%421) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %423 = "cute.make_layout"(%89, %422) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      "cf.br"(%95)[^bb7] : (i32) -> ()
    ^bb7(%424: i32):  // 2 preds: ^bb6, ^bb8
      %425 = "arith.cmpi"(%424, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%425)[^bb8, ^bb9] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb8:  // pred: ^bb7
      %426 = "cute.make_coord"(%424) : (i32) -> !cute.coord<"(_,?)">
      %427 = "cute.crd2idx"(%426, %423) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %428 = "cute.add_offset"(%255, %427) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %429 = "cute.crd2idx"(%426, %88) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %430 = "cute.add_offset"(%263, %429) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %431 = "cute.crd2idx"(%426, %87) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,1)))">) -> !cute.int_tuple<"?">
      %432 = "cute.add_offset"(%401, %431) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %433 = "builtin.unrealized_conversion_cast"(%432) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %434 = "llvm.load"(%433) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %435 = "llvm.trunc"(%434) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %436 = "cute.recast_iter"(%428) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
      %437 = "cute.recast_iter"(%430) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%437, %436, %435) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
      %438 = "arith.addi"(%424, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%438)[^bb7] : (i32) -> ()
    ^bb9:  // pred: ^bb7
      "nvvm.cp.async.commit.group"() : () -> ()
      %439 = "cute.make_coord"() : () -> !cute.coord<"(_,_,_,1)">
      %440 = "cute.crd2idx"(%439, %93) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"2048">
      %441 = "cute.add_offset"(%241, %440) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<f32, gmem, align<16>>
      %442 = "cute.crd2idx"(%439, %85) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"1024">
      %443 = "cute.add_offset"(%245, %442) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<f32, smem, align<16>>
      %444 = "builtin.unrealized_conversion_cast"(%353) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %445 = "llvm.load"(%444) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %446 = "llvm.trunc"(%445) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %447 = "cute.recast_iter"(%441) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %448 = "cute.recast_iter"(%443) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%448, %447, %446) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %449 = "cute.crd2idx"(%439, %259) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"8">
      %450 = "cute.add_offset"(%255, %449) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"8">) -> !cute.ptr<f32, gmem>
      %451 = "cute.crd2idx"(%439, %84) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"1056">
      %452 = "cute.add_offset"(%263, %451) : (!cute.ptr<f32, smem>, !cute.int_tuple<"1056">) -> !cute.ptr<f32, smem>
      "cf.br"(%95)[^bb10] : (i32) -> ()
    ^bb10(%453: i32):  // 2 preds: ^bb9, ^bb11
      %454 = "arith.cmpi"(%453, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%454)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %455 = "cute.make_coord"(%453) : (i32) -> !cute.coord<"(_,?)">
      %456 = "cute.crd2idx"(%455, %423) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %457 = "cute.add_offset"(%450, %456) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %458 = "cute.crd2idx"(%455, %88) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %459 = "cute.add_offset"(%452, %458) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %460 = "cute.crd2idx"(%455, %83) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %461 = "cute.add_offset"(%370, %460) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %462 = "builtin.unrealized_conversion_cast"(%461) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %463 = "llvm.load"(%462) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %464 = "llvm.trunc"(%463) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %465 = "cute.recast_iter"(%457) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
      %466 = "cute.recast_iter"(%459) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%466, %465, %464) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
      %467 = "arith.addi"(%453, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%467)[^bb10] : (i32) -> ()
    ^bb12:  // pred: ^bb10
      "nvvm.cp.async.commit.group"() : () -> ()
      %468 = "arith.divsi"(%114, %82) : (i32, i32) -> i32
      %469 = "arith.remsi"(%468, %82) : (i32, i32) -> i32
      %470 = "arith.remsi"(%469, %82) : (i32, i32) -> i32
      %471 = "arith.muli"(%470, %105) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %472 = "cute.assume"(%471) : (i32) -> !cute.i32<divby 4>
      %473 = "cute.make_int_tuple"(%472) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %474 = "cute.add_offset"(%232, %473) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %475 = "arith.remsi"(%114, %82) : (i32, i32) -> i32
      %476 = "arith.remsi"(%475, %82) : (i32, i32) -> i32
      %477 = "arith.muli"(%476, %105) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %478 = "cute.assume"(%477) : (i32) -> !cute.i32<divby 4>
      %479 = "cute.make_int_tuple"(%478) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %480 = "cute.add_offset"(%233, %479) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %481 = "cute.get_scalars"(%226) <{only_dynamic}> : (!cute.layout<"(128,128):(?{i64 div=256},1)">) -> i64
      %482 = "arith.muli"(%481, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %483 = "arith.muli"(%481, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %484 = "arith.extsi"(%470) : (i32) -> i64
      %485 = "arith.muli"(%484, %482) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %486 = "arith.extsi"(%477) : (i32) -> i64
      %487 = "arith.addi"(%485, %486) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %488 = "cute.assume"(%487) : (i64) -> !cute.i64<divby 4>
      %489 = "cute.make_int_tuple"(%488) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %490 = "cute.add_offset"(%229, %489) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %491 = "cute.assume"(%481) : (i64) -> !cute.i64<divby 256>
      %492 = "cute.assume"(%483) : (i64) -> !cute.i64<divby 16384>
      %493 = "cute.make_stride"(%491, %492) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %494 = "cute.make_layout"(%79, %493) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(4,2),(4,2))">, !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %495 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %496 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %497 = "cute.memref.alloca"() : () -> !memref_rmem_f32_1
      %498 = "cute.get_iter"(%497) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
      "cute.memref.store_vec"(%61, %497) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %499 = "cute.make_view"(%474) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_
      %500 = "builtin.unrealized_conversion_cast"(%499) : (!memref_smem_f32_) -> !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %501 = "cute.make_view"(%480) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_1
      %502 = "builtin.unrealized_conversion_cast"(%501) : (!memref_smem_f32_1) -> !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
      "llvm.inline_asm"(%94, %104) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %503 = "cute.get_iter"(%495) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
      "cf.br"(%95)[^bb13] : (i32) -> ()
    ^bb13(%504: i32):  // 2 preds: ^bb12, ^bb14
      %505 = "arith.cmpi"(%504, %86) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%505)[^bb14, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb14:  // pred: ^bb13
      %506 = "cute.make_coord"(%504) : (i32) -> !cute.coord<"(_,?)">
      %507 = "cute.crd2idx"(%506, %76) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %508 = "cute.add_offset"(%474, %507) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %509 = "cute.crd2idx"(%506, %75) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %510 = "cute.add_offset"(%503, %509) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %511 = "builtin.unrealized_conversion_cast"(%508) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
      %512 = "builtin.unrealized_conversion_cast"(%510) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %513 = "llvm.load"(%511) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
      "llvm.store"(%513, %512) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
      %514 = "arith.addi"(%504, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%514)[^bb13] : (i32) -> ()
    ^bb15:  // pred: ^bb13
      %515 = "cute.get_iter"(%496) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
      "cf.br"(%95)[^bb16] : (i32) -> ()
    ^bb16(%516: i32):  // 2 preds: ^bb15, ^bb17
      %517 = "arith.cmpi"(%516, %86) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%517)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %518 = "cute.make_coord"(%516) : (i32) -> !cute.coord<"(_,?)">
      %519 = "cute.crd2idx"(%518, %76) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %520 = "cute.add_offset"(%480, %519) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %521 = "cute.crd2idx"(%518, %75) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %522 = "cute.add_offset"(%515, %521) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %523 = "builtin.unrealized_conversion_cast"(%520) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
      %524 = "builtin.unrealized_conversion_cast"(%522) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %525 = "llvm.load"(%523) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
      "llvm.store"(%525, %524) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
      %526 = "arith.addi"(%516, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%526)[^bb16] : (i32) -> ()
    ^bb18:  // pred: ^bb16
      "cf.br"(%95, %500, %502, %86, %95, %86)[^bb19] : (i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32) -> ()
    ^bb19(%527: i32, %528: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %529: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %530: i32, %531: i32, %532: i32):  // 2 preds: ^bb18, ^bb52
      %533 = "arith.cmpi"(%527, %109) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%533)[^bb20, ^bb53] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb20:  // pred: ^bb19
      "cf.br"(%95, %528, %529, %530, %531, %532, %94)[^bb21] : (i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32, i32) -> ()
    ^bb21(%534: i32, %535: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %536: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %537: i32, %538: i32, %539: i32, %540: i32):  // 2 preds: ^bb20, ^bb51
      %541 = "arith.cmpi"(%534, %109) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%541)[^bb22, ^bb52] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {loop_annotation = #loop_annotation1} : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %542 = "arith.cmpi"(%534, %74) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%542)[^bb23, ^bb24] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb23:  // pred: ^bb22
      %543 = "cute.make_coord"(%538) : (i32) -> !cute.coord<"(_,_,_,?)">
      %544 = "cute.crd2idx"(%543, %78) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %545 = "cute.add_offset"(%474, %544) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
      %546 = "cute.make_view"(%545) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_
      %547 = "builtin.unrealized_conversion_cast"(%546) : (!memref_smem_f32_) -> !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %548 = "cute.crd2idx"(%543, %77) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
      %549 = "cute.add_offset"(%480, %548) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
      %550 = "cute.make_view"(%549) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_1
      %551 = "builtin.unrealized_conversion_cast"(%550) : (!memref_smem_f32_1) -> !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
      "llvm.inline_asm"(%94, %104) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      "cf.br"(%547, %551)[^bb25] : (!llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>) -> ()
    ^bb24:  // pred: ^bb22
      "cf.br"(%535, %536)[^bb25] : (!llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>) -> ()
    ^bb25(%552: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %553: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>):  // 2 preds: ^bb23, ^bb24
      "cf.br"()[^bb26] : () -> ()
    ^bb26:  // pred: ^bb25
      %554 = "builtin.unrealized_conversion_cast"(%553) : (!llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>) -> !memref_smem_f32_1
      %555 = "builtin.unrealized_conversion_cast"(%552) : (!llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>) -> !memref_smem_f32_
      %556 = "cute.make_coord"(%540) : (i32) -> !cute.coord<"(_,_,?)">
      %557 = "cute.crd2idx"(%556, %73) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),128)">) -> !cute.int_tuple<"?{div=128}">
      %558 = "cute.get_iter"(%555) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<16>>
      %559 = "cute.add_offset"(%558, %557) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, smem, align<16>>
      %560 = "cute.crd2idx"(%556, %72) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
      %561 = "cute.add_offset"(%503, %560) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      "cf.br"(%95)[^bb27] : (i32) -> ()
    ^bb27(%562: i32):  // 2 preds: ^bb26, ^bb28
      %563 = "arith.cmpi"(%562, %86) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%563)[^bb28, ^bb29] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb28:  // pred: ^bb27
      %564 = "cute.make_coord"(%562) : (i32) -> !cute.coord<"(_,?)">
      %565 = "cute.crd2idx"(%564, %76) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %566 = "cute.add_offset"(%559, %565) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %567 = "cute.crd2idx"(%564, %75) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %568 = "cute.add_offset"(%561, %567) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %569 = "builtin.unrealized_conversion_cast"(%566) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
      %570 = "builtin.unrealized_conversion_cast"(%568) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %571 = "llvm.load"(%569) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
      "llvm.store"(%571, %570) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
      %572 = "arith.addi"(%562, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%572)[^bb27] : (i32) -> ()
    ^bb29:  // pred: ^bb27
      %573 = "cute.crd2idx"(%556, %71) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),132)">) -> !cute.int_tuple<"?{div=132}">
      %574 = "cute.get_iter"(%554) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<16>>
      %575 = "cute.add_offset"(%574, %573) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=132}">) -> !cute.ptr<f32, smem, align<16>>
      %576 = "cute.add_offset"(%515, %560) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      "cf.br"(%95)[^bb30] : (i32) -> ()
    ^bb30(%577: i32):  // 2 preds: ^bb29, ^bb31
      %578 = "arith.cmpi"(%577, %86) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%578)[^bb31, ^bb32] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %579 = "cute.make_coord"(%577) : (i32) -> !cute.coord<"(_,?)">
      %580 = "cute.crd2idx"(%579, %76) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %581 = "cute.add_offset"(%575, %580) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %582 = "cute.crd2idx"(%579, %75) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %583 = "cute.add_offset"(%576, %582) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %584 = "builtin.unrealized_conversion_cast"(%581) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
      %585 = "builtin.unrealized_conversion_cast"(%583) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %586 = "llvm.load"(%584) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
      "llvm.store"(%586, %585) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
      %587 = "arith.addi"(%577, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%587)[^bb30] : (i32) -> ()
    ^bb32:  // pred: ^bb30
      %588 = "arith.cmpi"(%534, %95) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%588)[^bb33, ^bb34] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb33:  // pred: ^bb32
      %589 = "cute.make_coord"(%539) : (i32) -> !cute.coord<"(_,_,_,?)">
      %590 = "cute.crd2idx"(%589, %93) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %591 = "cute.add_offset"(%241, %590) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
      %592 = "cute.make_coord"(%537) : (i32) -> !cute.coord<"(_,_,_,?)">
      %593 = "cute.crd2idx"(%592, %85) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %594 = "cute.add_offset"(%245, %593) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
      %595 = "llvm.load"(%444) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %596 = "llvm.trunc"(%595) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %597 = "cute.recast_iter"(%591) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %598 = "cute.recast_iter"(%594) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%598, %597, %596) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      "cf.br"()[^bb34] : () -> ()
    ^bb34:  // 2 preds: ^bb32, ^bb33
      %599 = "cute.make_coord"(%534) : (i32) -> !cute.coord<"(_,_,?)">
      %600 = "cute.crd2idx"(%599, %72) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
      %601 = "cute.add_offset"(%503, %600) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      %602 = "cute.add_offset"(%515, %600) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      "cf.br"(%95)[^bb35] : (i32) -> ()
    ^bb35(%603: i32):  // 2 preds: ^bb34, ^bb39
      %604 = "arith.cmpi"(%603, %109) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%604)[^bb36, ^bb40] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %605 = "cute.make_coord"(%603) : (i32) -> !cute.coord<"(_,?,0)">
      %606 = "cute.crd2idx"(%605, %69) : (!cute.coord<"(_,?,0)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
      %607 = "cute.add_offset"(%601, %606) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %608 = "cute.make_view"(%607) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
      "cf.br"(%95)[^bb37] : (i32) -> ()
    ^bb37(%609: i32):  // 2 preds: ^bb36, ^bb38
      %610 = "arith.cmpi"(%609, %109) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%610)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %611 = "cute.make_coord"(%609) : (i32) -> !cute.coord<"(_,?,0)">
      %612 = "cute.make_coord"(%603, %609) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %613 = "cute.crd2idx"(%611, %69) : (!cute.coord<"(_,?,0)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
      %614 = "cute.add_offset"(%602, %613) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %615 = "cute.crd2idx"(%612, %70) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !cute.int_tuple<"?">
      %616 = "cute.add_offset"(%498, %615) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %617 = "cute.make_view"(%614) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
      %618 = "cute.make_view"(%616) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
      %619 = "cute.memref.load_vec"(%608) : (!memref_rmem_f32_2) -> vector<1xf32>
      %620 = "cute.memref.load_vec"(%617) : (!memref_rmem_f32_2) -> vector<1xf32>
      %621 = "cute.memref.load_vec"(%618) : (!memref_rmem_f32_2) -> vector<1xf32>
      %622 = "math.fma"(%619, %620, %621) <{fastmath = #arith.fastmath<none>}> : (vector<1xf32>, vector<1xf32>, vector<1xf32>) -> vector<1xf32>
      "cute.memref.store_vec"(%622, %618) : (vector<1xf32>, !memref_rmem_f32_2) -> ()
      %623 = "arith.addi"(%609, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%623)[^bb37] : (i32) -> ()
    ^bb39:  // pred: ^bb37
      %624 = "arith.addi"(%603, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%624)[^bb35] : (i32) -> ()
    ^bb40:  // pred: ^bb35
      %625 = "arith.select"(%588, %538, %537) : (i1, i32, i32) -> i32
      "cf.cond_br"(%588)[^bb41, ^bb49] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb41:  // pred: ^bb40
      %626 = "cute.make_coord"(%539) : (i32) -> !cute.coord<"(_,_,_,?)">
      %627 = "cute.crd2idx"(%626, %259) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
      %628 = "cute.add_offset"(%255, %627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %629 = "cute.make_coord"(%537) : (i32) -> !cute.coord<"(_,_,_,?)">
      %630 = "cute.crd2idx"(%629, %84) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
      %631 = "cute.add_offset"(%263, %630) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
      "cf.br"(%95)[^bb42] : (i32) -> ()
    ^bb42(%632: i32):  // 2 preds: ^bb41, ^bb43
      %633 = "arith.cmpi"(%632, %105) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%633)[^bb43, ^bb44] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb43:  // pred: ^bb42
      %634 = "cute.make_coord"(%632) : (i32) -> !cute.coord<"(_,?)">
      %635 = "cute.crd2idx"(%634, %423) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %636 = "cute.add_offset"(%628, %635) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %637 = "cute.crd2idx"(%634, %88) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %638 = "cute.add_offset"(%631, %637) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %639 = "cute.crd2idx"(%634, %83) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %640 = "cute.add_offset"(%370, %639) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %641 = "builtin.unrealized_conversion_cast"(%640) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %642 = "llvm.load"(%641) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %643 = "llvm.trunc"(%642) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %644 = "cute.recast_iter"(%636) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
      %645 = "cute.recast_iter"(%638) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%645, %644, %643) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
      %646 = "arith.addi"(%632, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%646)[^bb42] : (i32) -> ()
    ^bb44:  // pred: ^bb42
      "nvvm.cp.async.commit.group"() : () -> ()
      %647 = "arith.addi"(%538, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %648 = "arith.cmpi"(%647, %68) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %649 = "arith.select"(%648, %95, %647) : (i1, i32, i32) -> i32
      %650 = "arith.addi"(%539, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %651 = "arith.cmpi"(%650, %109) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%651)[^bb45, ^bb46] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb45:  // pred: ^bb44
      "cf.br"(%650)[^bb47] : (i32) -> ()
    ^bb46:  // pred: ^bb44
      "cf.br"(%94)[^bb47] : (i32) -> ()
    ^bb47(%652: i32):  // 2 preds: ^bb45, ^bb46
      "cf.br"()[^bb48] : () -> ()
    ^bb48:  // pred: ^bb47
      "cf.br"(%649, %652)[^bb50] : (i32, i32) -> ()
    ^bb49:  // pred: ^bb40
      "cf.br"(%538, %539)[^bb50] : (i32, i32) -> ()
    ^bb50(%653: i32, %654: i32):  // 2 preds: ^bb48, ^bb49
      "cf.br"()[^bb51] : () -> ()
    ^bb51:  // pred: ^bb50
      %655 = "arith.addi"(%540, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %656 = "arith.cmpi"(%655, %109) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %657 = "arith.select"(%656, %95, %655) : (i1, i32, i32) -> i32
      %658 = "arith.addi"(%534, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%658, %552, %553, %625, %653, %654, %657)[^bb21] : (i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32, i32) -> ()
    ^bb52:  // pred: ^bb21
      %659 = "arith.addi"(%527, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%659, %535, %536, %537, %538, %539)[^bb19] : (i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32) -> ()
    ^bb53:  // pred: ^bb19
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      "llvm.inline_asm"(%94, %104) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %660 = "cute.memref.load_vec"(%497) : (!memref_rmem_f32_1) -> vector<64xf32>
      "cute.memref.store_vec"(%660, %497) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %661 = "cute.make_int_tuple"(%472, %478) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %662 = "cute.add_offset"(%264, %661) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %663 = "cute.memref.alloca"() : () -> !memref_rmem_i8_6
      %664 = "cute.get_shape"(%177) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %665:2 = "cute.get_leaves"(%664) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
      %666 = "cute.to_int_tuple"(%665#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %667 = "arith.muli"(%115, %111) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %668 = "cute.make_int_tuple"(%667) : (i32) -> !cute.int_tuple<"?">
      %669 = "cute.tuple_sub"(%666, %668) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %670 = "cute.to_int_tuple"(%665#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
      %671 = "arith.muli"(%116, %111) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %672 = "cute.make_int_tuple"(%671) : (i32) -> !cute.int_tuple<"?">
      %673 = "cute.tuple_sub"(%670, %672) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %674 = "cute.make_coord"(%669, %673) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %675:2 = "cute.get_scalars"(%674) : (!cute.coord<"(?,?)">) -> (i32, i32)
      "cf.br"(%95)[^bb54] : (i32) -> ()
    ^bb54(%676: i32):  // 2 preds: ^bb53, ^bb55
      %677 = "arith.cmpi"(%676, %67) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%677)[^bb55, ^bb56] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb55:  // pred: ^bb54
      %678 = "cute.make_coord"(%676) : (i32) -> !cute.coord<"?">
      %679 = "cute.crd2idx"(%678, %66) : (!cute.coord<"?">, !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.int_tuple<"(?,?)">
      %680 = "cute.add_offset"(%662, %679) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %681 = "cute.deref_arith_tuple_iter"(%680) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %682:2 = "cute.get_leaves"(%681) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %683 = "cute.make_coord"(%682#0, %682#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %684:2 = "cute.get_scalars"(%683) : (!cute.coord<"(?,?)">) -> (i32, i32)
      %685 = "arith.cmpi"(%684#0, %675#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %686 = "arith.cmpi"(%684#1, %675#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %687 = "arith.andi"(%685, %686) : (i1, i1) -> i1
      %688 = "arith.extui"(%687) : (i1) -> i8
      "cute.memref.store"(%663, %678, %688) : (!memref_rmem_i8_6, !cute.coord<"?">, i8) -> ()
      %689 = "arith.addi"(%676, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%689)[^bb54] : (i32) -> ()
    ^bb56:  // pred: ^bb54
      %690 = "cute.get_iter"(%663) : (!memref_rmem_i8_6) -> !cute.ptr<i8, rmem, align<32>>
      %691 = "cute.append_to_rank"(%494, %113) <{rank = 2 : si32}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">, !cute.layout<"1:0">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %692:2 = "cute.get_scalars"(%691) <{only_dynamic}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> (i64, i64)
      %693 = "cute.assume"(%692#0) : (i64) -> !cute.i64<divby 256>
      %694 = "cute.assume"(%692#1) : (i64) -> !cute.i64<divby 16384>
      %695 = "cute.make_stride"(%693, %694) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %696 = "cute.make_layout"(%65, %695) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,((4,2),(4,2)))">, !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %697 = "cute.append_to_rank"(%696, %113) <{rank = 2 : si32}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">, !cute.layout<"1:0">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %698:2 = "cute.get_scalars"(%697) <{only_dynamic}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> (i64, i64)
      %699 = "cute.assume"(%698#0) : (i64) -> !cute.i64<divby 256>
      %700 = "cute.assume"(%698#1) : (i64) -> !cute.i64<divby 16384>
      %701 = "cute.make_stride"(%699, %700) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %702 = "cute.make_layout"(%63, %701) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(((4,2),(4,2))))">, !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      "cf.br"(%95)[^bb57] : (i32) -> ()
    ^bb57(%703: i32):  // 2 preds: ^bb56, ^bb60
      %704 = "arith.cmpi"(%703, %67) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%704)[^bb58, ^bb61] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb58:  // pred: ^bb57
      %705 = "cute.make_coord"(%703) : (i32) -> !cute.coord<"(_,?)">
      %706 = "cute.crd2idx"(%705, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
      %707 = "cute.add_offset"(%498, %706) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %708 = "cute.crd2idx"(%705, %702) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.int_tuple<"?{i64}">
      %709 = "cute.add_offset"(%490, %708) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %710 = "cute.add_offset"(%690, %706) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %711 = "builtin.unrealized_conversion_cast"(%710) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %712 = "llvm.load"(%711) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %713 = "llvm.icmp"(%712, %62) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%713)[^bb59, ^bb60] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb59:  // pred: ^bb58
      %714 = "builtin.unrealized_conversion_cast"(%707) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %715 = "builtin.unrealized_conversion_cast"(%709) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %716 = "llvm.load"(%714) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%716, %715) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb60] : () -> ()
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %717 = "arith.addi"(%703, %94) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%717)[^bb57] : (i32) -> ()
    ^bb61:  // pred: ^bb57
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 256, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2, !cuda.stream) -> i32, sym_name = "cutlass___call_____main__SGemm_object_at__Tensorgmemo256641256_Tensorgmemodiv64i64div641_Tensorgmemodiv256i64div2561_functionSGemmlambdaat_CUstream0x0"}> ({
  ^bb0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2, %arg3: !cuda.stream):
    %0 = "arith.constant"() <{value = 24944 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %3 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %5 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>
    %6 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>
    %7 = "cute.make_tiled_copy"(%6) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>) -> !copy_ldgsts
    %8 = "cute.make_tiled_copy"(%5) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>) -> !copy_ldgsts1
    %9 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
    %10 = "cute.get_shape"(%9) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
    %11:2 = "cute.get_leaves"(%10) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
    %12 = "cute.to_int_tuple"(%11#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.to_int_tuple"(%11#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
    %14 = "cute.make_int_tuple"(%12, %13) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?,?{div=256})">
    %15:2 = "cute.get_scalars"(%14) <{only_dynamic}> : (!cute.int_tuple<"(?,?{div=256})">) -> (i32, i32)
    %16 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %17 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %18 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %19 = "arith.cmpi"(%4, %17) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %20 = "arith.select"(%19, %18, %16) : (i1, i32, i32) -> i32
    %21 = "arith.addi"(%20, %15#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %22 = "arith.divsi"(%21, %4) : (i32, i32) -> i32
    %23 = "arith.addi"(%16, %22) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %24 = "arith.subi"(%17, %15#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %25 = "arith.divsi"(%24, %4) : (i32, i32) -> i32
    %26 = "arith.subi"(%17, %25) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %27 = "arith.cmpi"(%15#0, %17) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %28 = "arith.cmpi"(%15#0, %17) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %29 = "arith.cmpi"(%4, %17) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %30 = "arith.cmpi"(%4, %17) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %31 = "arith.andi"(%27, %29) : (i1, i1) -> i1
    %32 = "arith.andi"(%28, %30) : (i1, i1) -> i1
    %33 = "arith.ori"(%31, %32) : (i1, i1) -> i1
    %34 = "arith.select"(%33, %23, %26) : (i1, i32, i32) -> i32
    %35 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %36 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %37 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %38 = "arith.cmpi"(%4, %36) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %39 = "arith.select"(%38, %37, %35) : (i1, i32, i32) -> i32
    %40 = "arith.addi"(%39, %15#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %41 = "arith.divsi"(%40, %4) : (i32, i32) -> i32
    %42 = "arith.addi"(%35, %41) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %43 = "arith.subi"(%36, %15#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %44 = "arith.divsi"(%43, %4) : (i32, i32) -> i32
    %45 = "arith.subi"(%36, %44) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %46 = "arith.cmpi"(%15#1, %36) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %47 = "arith.cmpi"(%15#1, %36) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %48 = "arith.cmpi"(%4, %36) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %49 = "arith.cmpi"(%4, %36) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %50 = "arith.andi"(%46, %48) : (i1, i1) -> i1
    %51 = "arith.andi"(%47, %49) : (i1, i1) -> i1
    %52 = "arith.ori"(%50, %51) : (i1, i1) -> i1
    %53 = "arith.select"(%52, %42, %45) : (i1, i32, i32) -> i32
    %54 = "cute.make_int_tuple"(%34, %53) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %55:2 = "cute.get_leaves"(%54) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
    %56 = "cute.get_scalars"(%55#0) : (!cute.int_tuple<"?">) -> i32
    %57 = "cute.get_scalars"(%55#1) : (!cute.int_tuple<"?">) -> i32
    %58 = "cuda.launch_cfg.create"(%3, %2, %2, %0, %56, %57, %2, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%58, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%58, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %59 = "cuda.launch_ex"(%58, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %60 = "cuda.cast"(%59) : (!cuda.result) -> i32
    "cuda.return_if_error"(%60) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
