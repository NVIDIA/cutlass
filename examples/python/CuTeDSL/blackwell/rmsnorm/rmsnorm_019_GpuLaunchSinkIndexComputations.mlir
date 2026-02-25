!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, "(8):(1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> (), sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0"}> ({
    ^bb0(%arg6: !memref_gmem_bf16_, %arg7: !memref_gmem_bf16_1, %arg8: !memref_gmem_bf16_, %arg9: f32):
      %39 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %40 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %41 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %42 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %43 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %44 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %45 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %46 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(8))">
      %47 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(512))">
      %48 = "cute.static"() : () -> !cute.int_tuple<"56">
      %49 = "cute.static"() : () -> !cute.int_tuple<"48">
      %50 = "cute.static"() : () -> !cute.int_tuple<"40">
      %51 = "cute.static"() : () -> !cute.int_tuple<"32">
      %52 = "cute.static"() : () -> !cute.int_tuple<"24">
      %53 = "cute.static"() : () -> !cute.int_tuple<"16">
      %54 = "cute.static"() : () -> !cute.int_tuple<"8">
      %55 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %56 = "cute.static"() : () -> !cute.int_tuple<"7">
      %57 = "cute.static"() : () -> !cute.int_tuple<"3584">
      %58 = "cute.static"() : () -> !cute.int_tuple<"6">
      %59 = "cute.static"() : () -> !cute.int_tuple<"3072">
      %60 = "cute.static"() : () -> !cute.int_tuple<"5">
      %61 = "cute.static"() : () -> !cute.int_tuple<"2560">
      %62 = "cute.static"() : () -> !cute.int_tuple<"4">
      %63 = "cute.static"() : () -> !cute.int_tuple<"2048">
      %64 = "cute.static"() : () -> !cute.int_tuple<"3">
      %65 = "cute.static"() : () -> !cute.int_tuple<"1536">
      %66 = "cute.static"() : () -> !cute.int_tuple<"2">
      %67 = "cute.static"() : () -> !cute.int_tuple<"1024">
      %68 = "cute.static"() : () -> !cute.int_tuple<"512">
      %69 = "cute.static"() : () -> !cute.layout<"(8):(1)">
      %70 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %71 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %72 = "cute.static"() : () -> !cute.int_tuple<"1">
      %73 = "cute.static"() : () -> !cute.coord<"(7,0,0)">
      %74 = "cute.static"() : () -> !cute.int_tuple<"(0,3584)">
      %75 = "cute.static"() : () -> !cute.coord<"(6,0,0)">
      %76 = "cute.static"() : () -> !cute.int_tuple<"(0,3072)">
      %77 = "cute.static"() : () -> !cute.coord<"(5,0,0)">
      %78 = "cute.static"() : () -> !cute.int_tuple<"(0,2560)">
      %79 = "cute.static"() : () -> !cute.coord<"(4,0,0)">
      %80 = "cute.static"() : () -> !cute.int_tuple<"(0,2048)">
      %81 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
      %82 = "cute.static"() : () -> !cute.int_tuple<"(0,1536)">
      %83 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
      %84 = "cute.static"() : () -> !cute.int_tuple<"(0,1024)">
      %85 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
      %86 = "cute.static"() : () -> !cute.int_tuple<"(0,512)">
      %87 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      %88 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %89 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %90 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %91 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %92 = "cute.static"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %93 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %94 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %95 = "cute.static"() : () -> !cute.layout<"(2,2):(1,2)">
      %96 = "cute.static"() : () -> !cute.int_tuple<"16384">
      %97 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %98 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %99 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %100 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %101 = "cute.get_shape"(%100) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %102:2 = "cute.get_leaves"(%101) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %103 = "cute.to_int_tuple"(%102#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %104 = "cute.get_scalars"(%103) : (!cute.int_tuple<"?">) -> i32
      %105 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %106 = "cute.add_offset"(%105, %96) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %107 = "cute.recast_iter"(%105) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %108 = "cute.recast_iter"(%106) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %109 = "cute.make_view"(%108, %95) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %110 = "cute.make_shape"(%103) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %111 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %112 = "cute.make_layout"(%110, %94) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %113 = "cute.make_coord"(%99) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %114 = "cute.get_scalars"(%100) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %115 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %116 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %117 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %118 = "arith.cmpi"(%93, %116) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %119 = "arith.select"(%118, %117, %115) : (i1, i32, i32) -> i32
      %120 = "arith.addi"(%119, %114) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %121 = "arith.divsi"(%120, %93) : (i32, i32) -> i32
      %122 = "arith.addi"(%115, %121) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %123 = "arith.subi"(%116, %114) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %124 = "arith.divsi"(%123, %93) : (i32, i32) -> i32
      %125 = "arith.subi"(%116, %124) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %126 = "arith.cmpi"(%114, %116) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %127 = "arith.cmpi"(%114, %116) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %128 = "arith.cmpi"(%93, %116) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %129 = "arith.cmpi"(%93, %116) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %130 = "arith.andi"(%126, %128) : (i1, i1) -> i1
      %131 = "arith.andi"(%127, %129) : (i1, i1) -> i1
      %132 = "arith.ori"(%130, %131) : (i1, i1) -> i1
      %133 = "arith.select"(%132, %122, %125) : (i1, i32, i32) -> i32
      %134 = "cute.make_shape"(%133) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %135 = "cute.make_layout"(%134, %92) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %136 = "cute.crd2idx"(%113, %135) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %137 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %138 = "cute.add_offset"(%137, %136) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %139 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %140 = "cute.get_scalars"(%139) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %141 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %142 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %143 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %144 = "arith.cmpi"(%93, %142) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %145 = "arith.select"(%144, %143, %141) : (i1, i32, i32) -> i32
      %146 = "arith.addi"(%145, %140) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %147 = "arith.divsi"(%146, %93) : (i32, i32) -> i32
      %148 = "arith.addi"(%141, %147) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %149 = "arith.subi"(%142, %140) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %150 = "arith.divsi"(%149, %93) : (i32, i32) -> i32
      %151 = "arith.subi"(%142, %150) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %152 = "arith.cmpi"(%140, %142) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %153 = "arith.cmpi"(%140, %142) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %154 = "arith.cmpi"(%93, %142) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %155 = "arith.cmpi"(%93, %142) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %156 = "arith.andi"(%152, %154) : (i1, i1) -> i1
      %157 = "arith.andi"(%153, %155) : (i1, i1) -> i1
      %158 = "arith.ori"(%156, %157) : (i1, i1) -> i1
      %159 = "arith.select"(%158, %148, %151) : (i1, i32, i32) -> i32
      %160 = "cute.make_shape"(%159) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %161 = "cute.make_layout"(%160, %92) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %162 = "cute.crd2idx"(%113, %161) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %163 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %164 = "cute.add_offset"(%163, %162) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %165 = "cute.get_scalars"(%112) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %166 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %167 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %168 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %169 = "arith.cmpi"(%93, %167) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %170 = "arith.select"(%169, %168, %166) : (i1, i32, i32) -> i32
      %171 = "arith.addi"(%170, %165) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %172 = "arith.divsi"(%171, %93) : (i32, i32) -> i32
      %173 = "arith.addi"(%166, %172) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %174 = "arith.subi"(%167, %165) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %175 = "arith.divsi"(%174, %93) : (i32, i32) -> i32
      %176 = "arith.subi"(%167, %175) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %177 = "arith.cmpi"(%165, %167) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %178 = "arith.cmpi"(%165, %167) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %179 = "arith.cmpi"(%93, %167) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %180 = "arith.cmpi"(%93, %167) <{predicate = 4 : i64}> : (i32, i32) -> i1
      %181 = "arith.andi"(%177, %179) : (i1, i1) -> i1
      %182 = "arith.andi"(%178, %180) : (i1, i1) -> i1
      %183 = "arith.ori"(%181, %182) : (i1, i1) -> i1
      %184 = "arith.select"(%183, %173, %176) : (i1, i32, i32) -> i32
      %185 = "cute.make_shape"(%184) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %186 = "cute.make_layout"(%185, %91) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %187 = "cute.crd2idx"(%113, %186) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %188 = "cute.add_offset"(%111, %187) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %189 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %190 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %191 = "cute.make_tiled_copy"(%189) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %192 = "cute.make_tiled_copy"(%190) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %193 = "cute.make_tiled_copy"(%190) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %194 = "arith.divsi"(%98, %90) : (i32, i32) -> i32
      %195 = "arith.remsi"(%98, %90) : (i32, i32) -> i32
      %196 = "arith.muli"(%195, %89) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %197 = "arith.muli"(%194, %88) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %198 = "arith.addi"(%196, %197) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %199 = "cute.assume"(%198) : (i32) -> !cute.i32<divby 8>
      %200 = "cute.make_int_tuple"(%199) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %201 = "cute.add_offset"(%138, %200) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %202 = "cute.add_offset"(%107, %200) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %203 = "cute.add_offset"(%164, %200) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %204 = "cute.assume"(%196) : (i32) -> !cute.i32<divby 8>
      %205 = "cute.make_int_tuple"(%194, %204) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %206 = "cute.add_offset"(%188, %205) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %207 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %208 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %209 = "cute.get_iter"(%208) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %210 = "cute.make_int_tuple"(%204) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %211 = "cute.add_offset"(%97, %210) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %212 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %213 = "cute.get_iter"(%212) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %214 = "cute.make_view"(%213) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_
      %215 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %216 = "cute.get_iter"(%215) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %217 = "cute.deref_arith_tuple_iter"(%206) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %218:2 = "cute.get_leaves"(%217) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %219 = "cute.make_coord"(%218#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %220 = "cute.get_scalars"(%219) : (!cute.coord<"?{div=8}">) -> i32
      %221 = "arith.cmpi"(%220, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %222 = "arith.extui"(%221) : (i1) -> i8
      "cute.memref.store"(%215, %87, %222) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %223 = "cute.add_offset"(%206, %86) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %224 = "cute.deref_arith_tuple_iter"(%223) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %225:2 = "cute.get_leaves"(%224) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %226 = "cute.make_coord"(%225#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %227 = "cute.get_scalars"(%226) : (!cute.coord<"?{div=8}">) -> i32
      %228 = "arith.cmpi"(%227, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %229 = "arith.extui"(%228) : (i1) -> i8
      "cute.memref.store"(%215, %85, %229) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %230 = "cute.add_offset"(%206, %84) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %231 = "cute.deref_arith_tuple_iter"(%230) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %232:2 = "cute.get_leaves"(%231) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %233 = "cute.make_coord"(%232#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %234 = "cute.get_scalars"(%233) : (!cute.coord<"?{div=8}">) -> i32
      %235 = "arith.cmpi"(%234, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %236 = "arith.extui"(%235) : (i1) -> i8
      "cute.memref.store"(%215, %83, %236) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %237 = "cute.add_offset"(%206, %82) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %238 = "cute.deref_arith_tuple_iter"(%237) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %239:2 = "cute.get_leaves"(%238) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %240 = "cute.make_coord"(%239#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %241 = "cute.get_scalars"(%240) : (!cute.coord<"?{div=8}">) -> i32
      %242 = "arith.cmpi"(%241, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %243 = "arith.extui"(%242) : (i1) -> i8
      "cute.memref.store"(%215, %81, %243) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %244 = "cute.add_offset"(%206, %80) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %245 = "cute.deref_arith_tuple_iter"(%244) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %246:2 = "cute.get_leaves"(%245) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %247 = "cute.make_coord"(%246#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %248 = "cute.get_scalars"(%247) : (!cute.coord<"?{div=8}">) -> i32
      %249 = "arith.cmpi"(%248, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %250 = "arith.extui"(%249) : (i1) -> i8
      "cute.memref.store"(%215, %79, %250) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %251 = "cute.add_offset"(%206, %78) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %252 = "cute.deref_arith_tuple_iter"(%251) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %253:2 = "cute.get_leaves"(%252) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %254 = "cute.make_coord"(%253#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %255 = "cute.get_scalars"(%254) : (!cute.coord<"?{div=8}">) -> i32
      %256 = "arith.cmpi"(%255, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %257 = "arith.extui"(%256) : (i1) -> i8
      "cute.memref.store"(%215, %77, %257) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %258 = "cute.add_offset"(%206, %76) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %259 = "cute.deref_arith_tuple_iter"(%258) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %260:2 = "cute.get_leaves"(%259) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %261 = "cute.make_coord"(%260#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %262 = "cute.get_scalars"(%261) : (!cute.coord<"?{div=8}">) -> i32
      %263 = "arith.cmpi"(%262, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %264 = "arith.extui"(%263) : (i1) -> i8
      "cute.memref.store"(%215, %75, %264) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %265 = "cute.add_offset"(%206, %74) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %266 = "cute.deref_arith_tuple_iter"(%265) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %267:2 = "cute.get_leaves"(%266) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %268 = "cute.make_coord"(%267#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %269 = "cute.get_scalars"(%268) : (!cute.coord<"?{div=8}">) -> i32
      %270 = "arith.cmpi"(%269, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %271 = "arith.extui"(%270) : (i1) -> i8
      "cute.memref.store"(%215, %73, %271) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %272 = "cute.get_scalars"(%218#0) : (!cute.int_tuple<"?">) -> i32
      %273 = "arith.cmpi"(%272, %104) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%273)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %274 = "cute.make_view"(%216, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_1
      %275 = "cute.derefine"(%274) : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
      %276 = "cute.get_iter"(%275) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
      %277 = "builtin.unrealized_conversion_cast"(%276) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %278 = "llvm.load"(%277) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %279 = "llvm.trunc"(%278) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %280 = "cute.recast_iter"(%201) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %281 = "cute.recast_iter"(%202) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%281, %280, %279) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %282 = "cute.add_offset"(%201, %68) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %283 = "cute.add_offset"(%202, %68) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
      %284 = "cute.add_offset"(%276, %72) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %285 = "builtin.unrealized_conversion_cast"(%284) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %286 = "llvm.load"(%285) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %287 = "llvm.trunc"(%286) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %288 = "cute.recast_iter"(%282) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %289 = "cute.recast_iter"(%283) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%289, %288, %287) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %290 = "cute.add_offset"(%201, %67) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %291 = "cute.add_offset"(%202, %67) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %292 = "cute.add_offset"(%276, %66) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %293 = "builtin.unrealized_conversion_cast"(%292) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %294 = "llvm.load"(%293) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %295 = "llvm.trunc"(%294) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %296 = "cute.recast_iter"(%290) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %297 = "cute.recast_iter"(%291) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%297, %296, %295) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %298 = "cute.add_offset"(%201, %65) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %299 = "cute.add_offset"(%202, %65) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
      %300 = "cute.add_offset"(%276, %64) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %301 = "builtin.unrealized_conversion_cast"(%300) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %302 = "llvm.load"(%301) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %303 = "llvm.trunc"(%302) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %304 = "cute.recast_iter"(%298) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %305 = "cute.recast_iter"(%299) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%305, %304, %303) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %306 = "cute.add_offset"(%201, %63) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %307 = "cute.add_offset"(%202, %63) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %308 = "cute.add_offset"(%276, %62) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %309 = "builtin.unrealized_conversion_cast"(%308) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %310 = "llvm.load"(%309) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %311 = "llvm.trunc"(%310) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %312 = "cute.recast_iter"(%306) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %313 = "cute.recast_iter"(%307) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%313, %312, %311) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %314 = "cute.add_offset"(%201, %61) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %315 = "cute.add_offset"(%202, %61) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
      %316 = "cute.add_offset"(%276, %60) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %317 = "builtin.unrealized_conversion_cast"(%316) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %318 = "llvm.load"(%317) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %319 = "llvm.trunc"(%318) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %320 = "cute.recast_iter"(%314) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %321 = "cute.recast_iter"(%315) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%321, %320, %319) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %322 = "cute.add_offset"(%201, %59) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %323 = "cute.add_offset"(%202, %59) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %324 = "cute.add_offset"(%276, %58) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %325 = "builtin.unrealized_conversion_cast"(%324) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %326 = "llvm.load"(%325) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %327 = "llvm.trunc"(%326) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %328 = "cute.recast_iter"(%322) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %329 = "cute.recast_iter"(%323) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%329, %328, %327) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %330 = "cute.add_offset"(%201, %57) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %331 = "cute.add_offset"(%202, %57) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
      %332 = "cute.add_offset"(%276, %56) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %333 = "builtin.unrealized_conversion_cast"(%332) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %334 = "llvm.load"(%333) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %335 = "llvm.trunc"(%334) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %336 = "cute.recast_iter"(%330) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %337 = "cute.recast_iter"(%331) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%337, %336, %335) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "nvvm.cp.async.commit.group"() : () -> ()
      %338 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %339 = "cute.get_iter"(%338) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      "cute.memref.store"(%338, %87, %222) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %85, %229) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %83, %236) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %81, %243) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %79, %250) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %77, %257) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %75, %264) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      "cute.memref.store"(%338, %73, %271) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %340 = "cute.derefine"(%339) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %341 = "builtin.unrealized_conversion_cast"(%340) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %342 = "llvm.load"(%341) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %343 = "llvm.icmp"(%342, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%343)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      %344 = "builtin.unrealized_conversion_cast"(%211) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %345 = "builtin.unrealized_conversion_cast"(%213) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %346 = "llvm.load"(%344) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%346, %345) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %347 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
      %348 = "cute.add_offset"(%339, %347) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %349 = "builtin.unrealized_conversion_cast"(%348) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %350 = "llvm.load"(%349) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %351 = "llvm.icmp"(%350, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%351)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %352 = "cute.add_offset"(%211, %68) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %353 = "cute.add_offset"(%213, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %354 = "builtin.unrealized_conversion_cast"(%352) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %355 = "builtin.unrealized_conversion_cast"(%353) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %356 = "llvm.load"(%354) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%356, %355) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %357 = "cute.add_offset"(%339, %66) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %358 = "cute.derefine"(%357) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %359 = "builtin.unrealized_conversion_cast"(%358) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %360 = "llvm.load"(%359) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %361 = "llvm.icmp"(%360, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%361)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %362 = "cute.add_offset"(%211, %67) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %363 = "cute.add_offset"(%213, %53) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %364 = "builtin.unrealized_conversion_cast"(%362) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %365 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %366 = "llvm.load"(%364) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%366, %365) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %367 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
      %368 = "cute.add_offset"(%339, %367) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %369 = "builtin.unrealized_conversion_cast"(%368) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %370 = "llvm.load"(%369) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %371 = "llvm.icmp"(%370, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%371)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %372 = "cute.add_offset"(%211, %65) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %373 = "cute.add_offset"(%213, %52) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %374 = "builtin.unrealized_conversion_cast"(%372) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %375 = "builtin.unrealized_conversion_cast"(%373) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %376 = "llvm.load"(%374) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%376, %375) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %377 = "cute.add_offset"(%339, %62) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %378 = "cute.derefine"(%377) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %379 = "builtin.unrealized_conversion_cast"(%378) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %380 = "llvm.load"(%379) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %381 = "llvm.icmp"(%380, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%381)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %382 = "cute.add_offset"(%211, %63) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %383 = "cute.add_offset"(%213, %51) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %384 = "builtin.unrealized_conversion_cast"(%382) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %385 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %386 = "llvm.load"(%384) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%386, %385) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %387 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
      %388 = "cute.add_offset"(%339, %387) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %389 = "builtin.unrealized_conversion_cast"(%388) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %390 = "llvm.load"(%389) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %391 = "llvm.icmp"(%390, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%391)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %392 = "cute.add_offset"(%211, %61) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %393 = "cute.add_offset"(%213, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %394 = "builtin.unrealized_conversion_cast"(%392) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %395 = "builtin.unrealized_conversion_cast"(%393) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %396 = "llvm.load"(%394) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%396, %395) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb14] : () -> ()
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %397 = "cute.add_offset"(%339, %58) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %398 = "cute.derefine"(%397) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %399 = "builtin.unrealized_conversion_cast"(%398) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %400 = "llvm.load"(%399) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %401 = "llvm.icmp"(%400, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%401)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %402 = "cute.add_offset"(%211, %59) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %403 = "cute.add_offset"(%213, %49) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %404 = "builtin.unrealized_conversion_cast"(%402) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %405 = "builtin.unrealized_conversion_cast"(%403) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %406 = "llvm.load"(%404) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%406, %405) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb16] : () -> ()
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %407 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
      %408 = "cute.add_offset"(%339, %407) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %409 = "builtin.unrealized_conversion_cast"(%408) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %410 = "llvm.load"(%409) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %411 = "llvm.icmp"(%410, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%411)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %412 = "cute.add_offset"(%211, %57) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %413 = "cute.add_offset"(%213, %48) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %414 = "builtin.unrealized_conversion_cast"(%412) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %415 = "builtin.unrealized_conversion_cast"(%413) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %416 = "llvm.load"(%414) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%416, %415) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb18] : () -> ()
    ^bb18:  // 2 preds: ^bb16, ^bb17
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %417 = "cute.get_iter"(%207) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      "cf.br"(%71)[^bb19] : (i32) -> ()
    ^bb19(%418: i32):  // 2 preds: ^bb18, ^bb20
      %419 = "arith.cmpi"(%418, %89) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%419)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %420 = "cute.make_coord"(%418) : (i32) -> !cute.coord<"(_,?)">
      %421 = "cute.crd2idx"(%420, %47) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %422 = "cute.add_offset"(%202, %421) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %423 = "cute.crd2idx"(%420, %46) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %424 = "cute.add_offset"(%417, %423) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %425 = "builtin.unrealized_conversion_cast"(%422) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
      %426 = "builtin.unrealized_conversion_cast"(%424) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %427 = "llvm.load"(%425) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%427, %426) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %428 = "arith.addi"(%418, %70) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%428)[^bb19] : (i32) -> ()
    ^bb21:  // pred: ^bb19
      %429 = "cute.memref.load_vec"(%207) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %430 = "arith.extf"(%429) : (vector<64xbf16>) -> vector<64xf32>
      %431 = "arith.mulf"(%430, %430) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %432 = "vector.reduction"(%431, %45) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %433 = "nvvm.shfl.sync"(%44, %432, %43, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %434 = "arith.addf"(%433, %432) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %435 = "nvvm.shfl.sync"(%44, %434, %89, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %436 = "arith.addf"(%434, %435) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %437 = "nvvm.shfl.sync"(%44, %436, %41, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %438 = "arith.addf"(%436, %437) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %439 = "nvvm.shfl.sync"(%44, %438, %93, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %440 = "arith.addf"(%438, %439) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %441 = "nvvm.shfl.sync"(%44, %440, %70, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %442 = "arith.addf"(%440, %441) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %443 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %444 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %445 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %446 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %447 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %448 = "arith.muli"(%444, %446) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %449 = "arith.addi"(%98, %448) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %450 = "arith.muli"(%445, %446) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %451 = "arith.muli"(%450, %447) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %452 = "arith.addi"(%449, %451) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %453 = "arith.divsi"(%452, %40) : (i32, i32) -> i32
      %454 = "arith.muli"(%453, %40) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %455 = "arith.cmpi"(%452, %454) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %456 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %457 = "arith.cmpi"(%452, %456) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %458 = "arith.cmpi"(%40, %456) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %459 = "arith.cmpi"(%457, %458) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %460 = "arith.andi"(%455, %459) : (i1, i1) -> i1
      %461 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %462 = "arith.addi"(%453, %461) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %463 = "arith.select"(%460, %462, %453) : (i1, i32, i32) -> i32
      %464 = "arith.divsi"(%463, %93) : (i32, i32) -> i32
      %465 = "arith.muli"(%464, %93) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %466 = "arith.cmpi"(%463, %465) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %467 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %468 = "arith.cmpi"(%463, %467) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %469 = "arith.cmpi"(%93, %467) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %470 = "arith.cmpi"(%468, %469) <{predicate = 1 : i64}> : (i1, i1) -> i1
      %471 = "arith.andi"(%466, %470) : (i1, i1) -> i1
      %472 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %473 = "arith.addi"(%464, %472) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %474 = "arith.select"(%471, %473, %464) : (i1, i32, i32) -> i32
      %475 = "arith.remsi"(%463, %93) : (i32, i32) -> i32
      %476 = "arith.cmpi"(%443, %71) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%476)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %477 = "cute.make_coord"(%474, %475) : (i32, i32) -> !cute.coord<"(?,?)">
      "cute.memref.store"(%109, %477, %442) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      "cf.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      "llvm.inline_asm"(%71) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %478 = "arith.cmpi"(%443, %93) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%478)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %479 = "cute.make_coord"(%474, %443) : (i32, i32) -> !cute.coord<"(?,?)">
      %480 = "cute.memref.load"(%109, %479) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
      "cf.br"(%480)[^bb26] : (f32) -> ()
    ^bb25:  // pred: ^bb23
      "cf.br"(%45)[^bb26] : (f32) -> ()
    ^bb26(%481: f32):  // 2 preds: ^bb24, ^bb25
      "cf.br"()[^bb27] : () -> ()
    ^bb27:  // pred: ^bb26
      %482 = "nvvm.shfl.sync"(%44, %481, %43, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %483 = "arith.addf"(%481, %482) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %484 = "nvvm.shfl.sync"(%44, %483, %89, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %485 = "arith.addf"(%483, %484) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %486 = "nvvm.shfl.sync"(%44, %485, %41, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %487 = "arith.addf"(%485, %486) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %488 = "nvvm.shfl.sync"(%44, %487, %93, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %489 = "arith.addf"(%487, %488) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %490 = "nvvm.shfl.sync"(%44, %489, %70, %42) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %491 = "arith.addf"(%489, %490) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %492 = "arith.divf"(%491, %39) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %493 = "arith.addf"(%492, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %494 = "math.rsqrt"(%493) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%71) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "cf.br"(%71)[^bb28] : (i32) -> ()
    ^bb28(%495: i32):  // 2 preds: ^bb27, ^bb29
      %496 = "arith.cmpi"(%495, %89) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%496)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb29:  // pred: ^bb28
      %497 = "cute.make_coord"(%495) : (i32) -> !cute.coord<"(_,?)">
      %498 = "cute.crd2idx"(%497, %47) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %499 = "cute.add_offset"(%202, %498) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %500 = "cute.crd2idx"(%497, %46) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %501 = "cute.add_offset"(%417, %500) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %502 = "builtin.unrealized_conversion_cast"(%499) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
      %503 = "builtin.unrealized_conversion_cast"(%501) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %504 = "llvm.load"(%502) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%504, %503) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %505 = "arith.addi"(%495, %70) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%505)[^bb28] : (i32) -> ()
    ^bb30:  // pred: ^bb28
      %506 = "cute.memref.load_vec"(%207) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %507 = "arith.extf"(%506) : (vector<64xbf16>) -> vector<64xf32>
      %508 = "vector.broadcast"(%494) : (f32) -> vector<64xf32>
      %509 = "arith.mulf"(%507, %508) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %510 = "cute.memref.load_vec"(%214) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %511 = "arith.extf"(%510) : (vector<64xbf16>) -> vector<64xf32>
      %512 = "arith.mulf"(%509, %511) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %513 = "arith.truncf"(%512) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%513, %208) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "cf.cond_br"(%273)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %514 = "cute.derefine"(%216) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %515 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %516 = "llvm.load"(%515) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %517 = "llvm.icmp"(%516, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%517)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %518 = "builtin.unrealized_conversion_cast"(%209) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %519 = "builtin.unrealized_conversion_cast"(%203) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %520 = "llvm.load"(%518) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%520, %519) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %521 = "cute.add_offset"(%216, %347) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %522 = "builtin.unrealized_conversion_cast"(%521) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %523 = "llvm.load"(%522) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %524 = "llvm.icmp"(%523, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%524)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %525 = "cute.add_offset"(%209, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %526 = "cute.add_offset"(%203, %68) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %527 = "builtin.unrealized_conversion_cast"(%525) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %528 = "builtin.unrealized_conversion_cast"(%526) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %529 = "llvm.load"(%527) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%529, %528) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %530 = "cute.add_offset"(%216, %66) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %531 = "cute.derefine"(%530) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %532 = "builtin.unrealized_conversion_cast"(%531) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %533 = "llvm.load"(%532) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %534 = "llvm.icmp"(%533, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%534)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %535 = "cute.add_offset"(%209, %53) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %536 = "cute.add_offset"(%203, %67) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %537 = "builtin.unrealized_conversion_cast"(%535) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %538 = "builtin.unrealized_conversion_cast"(%536) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %539 = "llvm.load"(%537) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%539, %538) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %540 = "cute.add_offset"(%216, %367) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %541 = "builtin.unrealized_conversion_cast"(%540) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %542 = "llvm.load"(%541) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %543 = "llvm.icmp"(%542, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%543)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %544 = "cute.add_offset"(%209, %52) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %545 = "cute.add_offset"(%203, %65) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %546 = "builtin.unrealized_conversion_cast"(%544) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %547 = "builtin.unrealized_conversion_cast"(%545) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %548 = "llvm.load"(%546) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%548, %547) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %549 = "cute.add_offset"(%216, %62) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %550 = "cute.derefine"(%549) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %551 = "builtin.unrealized_conversion_cast"(%550) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %552 = "llvm.load"(%551) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %553 = "llvm.icmp"(%552, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%553)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %554 = "cute.add_offset"(%209, %51) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %555 = "cute.add_offset"(%203, %63) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %556 = "builtin.unrealized_conversion_cast"(%554) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %557 = "builtin.unrealized_conversion_cast"(%555) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %558 = "llvm.load"(%556) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%558, %557) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %559 = "cute.add_offset"(%216, %387) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %560 = "builtin.unrealized_conversion_cast"(%559) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %561 = "llvm.load"(%560) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %562 = "llvm.icmp"(%561, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%562)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %563 = "cute.add_offset"(%209, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %564 = "cute.add_offset"(%203, %61) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %565 = "builtin.unrealized_conversion_cast"(%563) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %566 = "builtin.unrealized_conversion_cast"(%564) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %567 = "llvm.load"(%565) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%567, %566) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %568 = "cute.add_offset"(%216, %58) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %569 = "cute.derefine"(%568) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %570 = "builtin.unrealized_conversion_cast"(%569) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %571 = "llvm.load"(%570) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %572 = "llvm.icmp"(%571, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%572)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %573 = "cute.add_offset"(%209, %49) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %574 = "cute.add_offset"(%203, %59) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %575 = "builtin.unrealized_conversion_cast"(%573) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %576 = "builtin.unrealized_conversion_cast"(%574) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %577 = "llvm.load"(%575) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%577, %576) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %578 = "cute.add_offset"(%216, %407) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %579 = "builtin.unrealized_conversion_cast"(%578) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %580 = "llvm.load"(%579) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %581 = "llvm.icmp"(%580, %55) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%581)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %582 = "cute.add_offset"(%209, %48) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %583 = "cute.add_offset"(%203, %57) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %584 = "builtin.unrealized_conversion_cast"(%582) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %585 = "builtin.unrealized_conversion_cast"(%583) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %586 = "llvm.load"(%584) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%586, %585) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb47] : () -> ()
    ^bb47:  // 2 preds: ^bb45, ^bb46
      "cf.br"()[^bb48] : () -> ()
    ^bb48:  // 2 preds: ^bb30, ^bb47
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!cute.ptr<bf16, gmem, align<16>>, !cute.ptr<bf16, gmem, align<16>>, !cute.ptr<bf16, gmem, align<16>>, i32, f32, !cuda.stream) -> i32, sym_name = "cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0"}> ({
  ^bb0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream):
    %0 = "arith.constant"() <{value = 16400 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %3 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 2 : i32}> : () -> i32
    %5 = "cute.static"() : () -> !cute.layout<"(4096):(1)">
    %6 = "cute.static"() : () -> !cute.stride<"(4096,1)">
    %7 = "cute.make_shape"(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %8 = "cute.make_layout"(%7, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %9 = "cute.make_view"(%arg0, %8) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %10 = "cute.make_view"(%arg2, %8) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %11 = "cute.make_view"(%arg1, %5) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(4096):(1)">) -> !memref_gmem_bf16_1
    %12 = "cute.make_int_tuple"(%arg3) : (i32) -> !cute.int_tuple<"?">
    %13 = "cute.get_scalars"(%12) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
    %14 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %15 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %16 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %17 = "arith.cmpi"(%4, %15) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %18 = "arith.select"(%17, %16, %14) : (i1, i32, i32) -> i32
    %19 = "arith.addi"(%18, %13) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %20 = "arith.divsi"(%19, %4) : (i32, i32) -> i32
    %21 = "arith.addi"(%14, %20) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %22 = "arith.subi"(%15, %13) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %23 = "arith.divsi"(%22, %4) : (i32, i32) -> i32
    %24 = "arith.subi"(%15, %23) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %25 = "arith.cmpi"(%13, %15) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %26 = "arith.cmpi"(%13, %15) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %27 = "arith.cmpi"(%4, %15) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %28 = "arith.cmpi"(%4, %15) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %29 = "arith.andi"(%25, %27) : (i1, i1) -> i1
    %30 = "arith.andi"(%26, %28) : (i1, i1) -> i1
    %31 = "arith.ori"(%29, %30) : (i1, i1) -> i1
    %32 = "arith.select"(%31, %21, %24) : (i1, i32, i32) -> i32
    %33 = "cute.make_int_tuple"(%32) : (i32) -> !cute.int_tuple<"?">
    %34 = "cute.get_leaves"(%33) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %35 = "cute.get_scalars"(%34) : (!cute.int_tuple<"?">) -> i32
    %36 = "cuda.launch_cfg.create"(%3, %2, %2, %0, %35, %2, %2, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%36, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%36, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %37 = "cuda.launch_ex"(%36, %9, %11, %10, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %38 = "cuda.cast"(%37) : (!cuda.result) -> i32
    "cuda.return_if_error"(%38) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
