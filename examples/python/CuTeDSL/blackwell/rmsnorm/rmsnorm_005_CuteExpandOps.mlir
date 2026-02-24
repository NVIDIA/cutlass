!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(4096,1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "((2),4096):((0),1)">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(0,1)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_gmem_bf16_7 = !cute.memref<bf16, gmem, align<16>, "((8,8)):((1,512))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((8,8),(1,1)):((1,8),(0,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "((8,8)):((1,8))">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "(8,8):(1,8)">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<16>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8,(1,1)):(1,(0,1))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, "(8):(1)">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "(2,4096):(4096,1)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,8)):((1,512))">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "(8,8):(1,512)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<16>, "(8):(1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> (), sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0"}> ({
    ^bb0(%arg6: !memref_gmem_bf16_, %arg7: !memref_gmem_bf16_1, %arg8: !memref_gmem_bf16_, %arg9: f32):
      %39 = "cute.static"() : () -> !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
      %40 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %41 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %42 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %43 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %44 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %45 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %46 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %47 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %48 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %49 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %50 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %51 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %52 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %53 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %54 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %55 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %56 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %57 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %58 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %59 = "cute.get_shape"(%58) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %60:2 = "cute.get_leaves"(%59) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %61 = "cute.to_int_tuple"(%60#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %62 = "cute.get_scalars"(%61) : (!cute.int_tuple<"?">) -> i32
      %63 = "cute.get_shape"(%39) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %64:4 = "cute.get_leaves"(%63) : (!cute.shape<"((64,2),(8,8))">) -> (!cute.shape<"64">, !cute.shape<"2">, !cute.shape<"8">, !cute.shape<"8">)
      %65 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %66 = "cute.make_shape"() : () -> !cute.shape<"(2,4096)">
      %67 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
      %68 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(2,4096):(4096,1)">
      %69 = "cute.make_coord"() : () -> !cute.coord<"0">
      %70 = "cute.crd2idx"(%69, %68) : (!cute.coord<"0">, !cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"0">
      %71 = "cute.get_leaves"(%70) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %72 = "cute.cosize"(%68) <{mode = array<i32>}> : (!cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"8192">
      %73 = "cute.get_leaves"(%72) : (!cute.int_tuple<"8192">) -> !cute.int_tuple<"8192">
      %74 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16384">
      %75 = "cute.add_offset"(%65, %74) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %76 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %77 = "arith.constant"() <{value = 16384 : i32}> : () -> i32
      %78 = "arith.cmpi"(%76, %77) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %79 = "cute.recast_iter"(%65) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %80 = "cute.make_view"(%79, %68) : (!cute.ptr<bf16, smem, align<1024>>, !cute.layout<"(2,4096):(4096,1)">) -> !memref_smem_bf16_
      %81 = "cute.get_iter"(%80) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %82 = "cute.make_shape"() : () -> !cute.shape<"(2,2)">
      %83 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(2,2):(1,2)">
      %84 = "cute.make_coord"() : () -> !cute.coord<"0">
      %85 = "cute.crd2idx"(%84, %83) : (!cute.coord<"0">, !cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"0">
      %86 = "cute.get_leaves"(%85) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %87 = "cute.cosize"(%83) <{mode = array<i32>}> : (!cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"4">
      %88 = "cute.get_leaves"(%87) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %89 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
      %90 = "cute.add_offset"(%75, %89) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i8, smem, align<16>>
      %91 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %92 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
      %93 = "arith.cmpi"(%91, %92) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %94 = "cute.recast_iter"(%75) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %95 = "cute.make_view"(%94, %83) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %96 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %97 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %98 = "cute.get_shape"(%97) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %99:2 = "cute.get_leaves"(%98) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %100 = "cute.to_int_tuple"(%99#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %101 = "cute.get_scalars"(%100) : (!cute.int_tuple<"?">) -> i32
      %102 = "cute.make_shape"(%100) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %103 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %104 = "cute.make_stride"() : () -> !cute.stride<"(1@0,1@1)">
      %105 = "cute.make_layout"(%102, %104) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %106 = "cute.make_view"(%103, %105) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,4096):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %107 = "cute.get_iter"(%106) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %108 = "cute.deref_arith_tuple_iter"(%107) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %109:2 = "cute.get_leaves"(%108) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %110 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %111 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %112 = "cute.get_scalars"(%111) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %113 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %114 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %115 = "cute.get_scalars"(%114) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %116 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %117 = "arith.ceildivsi"(%115, %116) : (i32, i32) -> i32
      %118 = "cute.make_shape"(%117) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %119 = "cute.make_stride"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %120 = "cute.make_layout"(%118, %119) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %121 = "cute.crd2idx"(%113, %120) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %122 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %123 = "cute.add_offset"(%122, %121) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %124 = "cute.make_view"(%123) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %125 = "cute.get_iter"(%124) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %126 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %127 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %128 = "cute.get_scalars"(%127) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %129 = "cute.make_coord"(%128) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %130 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %131 = "cute.get_scalars"(%130) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %132 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %133 = "arith.ceildivsi"(%131, %132) : (i32, i32) -> i32
      %134 = "cute.make_shape"(%133) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %135 = "cute.make_stride"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %136 = "cute.make_layout"(%134, %135) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %137 = "cute.crd2idx"(%129, %136) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %138 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %139 = "cute.add_offset"(%138, %137) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %140 = "cute.make_view"(%139) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %141 = "cute.get_iter"(%140) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %142 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %143 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %144 = "cute.get_scalars"(%143) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %145 = "cute.make_coord"(%144) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %146 = "cute.get_layout"(%106) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %147 = "cute.get_scalars"(%146) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %148 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %149 = "arith.ceildivsi"(%147, %148) : (i32, i32) -> i32
      %150 = "cute.make_shape"(%149) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %151 = "cute.make_stride"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %152 = "cute.make_layout"(%150, %151) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %153 = "cute.crd2idx"(%145, %152) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %154 = "cute.get_iter"(%106) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %155 = "cute.add_offset"(%154, %153) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %156 = "cute.make_view"(%155) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %157 = "cute.get_iter"(%156) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %158 = "cute.deref_arith_tuple_iter"(%157) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %159:2 = "cute.get_leaves"(%158) : (!cute.int_tuple<"(?{div=2},0)">) -> (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"0">)
      %160 = "cute.get_scalars"(%159#0) : (!cute.int_tuple<"?{div=2}">) -> i32
      %161 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %162 = "cute.make_shape"() : () -> !cute.shape<"(2)">
      %163 = "cute.make_stride"() : () -> !cute.stride<"(0)">
      %164 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(2):(0)">
      %165 = "cute.get_shape"(%161) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %166 = "cute.get_leaves"(%165) : (!cute.shape<"(4096)">) -> !cute.shape<"4096">
      %167 = "cute.prepend_to_rank"(%161, %164) <{rank = 2 : si32}> : (!cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">) -> !cute.layout<"((2),4096):((0),1)">
      %168 = "cute.make_view"(%44, %167) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((2),4096):((0),1)">) -> !memref_gmem_bf16_3
      %169 = "cute.get_iter"(%168) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %170 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %171 = "cute.make_coord"() : () -> !cute.coord<"(0,0)">
      %172 = "cute.make_coord"() : () -> !cute.coord<"((_,_),(0,0))">
      %173 = "cute.get_layout"(%168) : (!memref_gmem_bf16_3) -> !cute.layout<"((2),4096):((0),1)">
      %174 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">
      %175 = "cute.crd2idx"(%172, %174) : (!cute.coord<"((_,_),(0,0))">, !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">) -> !cute.int_tuple<"0">
      %176 = "cute.get_iter"(%168) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %177 = "cute.add_offset"(%176, %175) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %178 = "cute.make_view"(%177) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_4
      %179 = "cute.get_iter"(%178) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %180 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %181 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %182 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %183 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %184 = "cute.make_tiled_copy"(%180) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %185 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %186 = "cute.make_tiled_copy"(%181) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %187 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %188 = "cute.make_tiled_copy"(%182) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %189 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %190 = "cute.get_iter"(%124) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %191 = "cute.get_scalars"(%189) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %192 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %193 = "arith.divsi"(%191, %192) : (i32, i32) -> i32
      %194 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %195 = "arith.remsi"(%191, %194) : (i32, i32) -> i32
      %196 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %197 = "arith.muli"(%195, %196) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %198 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %199 = "arith.muli"(%193, %198) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %200 = "arith.addi"(%197, %199) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %201 = "cute.assume"(%200) : (i32) -> !cute.i32<divby 8>
      %202 = "cute.make_int_tuple"(%201) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %203 = "cute.add_offset"(%190, %202) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %204 = "cute.make_view"(%203) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %205 = "cute.get_iter"(%204) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %206 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %207 = "cute.get_iter"(%80) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %208 = "cute.get_scalars"(%206) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %209 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %210 = "arith.divsi"(%208, %209) : (i32, i32) -> i32
      %211 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %212 = "arith.remsi"(%208, %211) : (i32, i32) -> i32
      %213 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %214 = "arith.muli"(%212, %213) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %215 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %216 = "arith.muli"(%210, %215) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %217 = "arith.addi"(%214, %216) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %218 = "cute.assume"(%217) : (i32) -> !cute.i32<divby 8>
      %219 = "cute.make_int_tuple"(%218) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %220 = "cute.add_offset"(%207, %219) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %221 = "cute.make_view"(%220) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_1
      %222 = "cute.get_iter"(%221) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %223 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %224 = "cute.get_iter"(%140) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %225 = "cute.get_scalars"(%223) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %226 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %227 = "arith.divsi"(%225, %226) : (i32, i32) -> i32
      %228 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %229 = "arith.remsi"(%225, %228) : (i32, i32) -> i32
      %230 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %231 = "arith.muli"(%229, %230) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %232 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %233 = "arith.muli"(%227, %232) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %234 = "arith.addi"(%231, %233) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %235 = "cute.assume"(%234) : (i32) -> !cute.i32<divby 8>
      %236 = "cute.make_int_tuple"(%235) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %237 = "cute.add_offset"(%224, %236) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %238 = "cute.make_view"(%237) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %239 = "cute.get_iter"(%238) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %240 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %241 = "cute.get_iter"(%156) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %242 = "cute.get_scalars"(%240) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %243 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %244 = "arith.divsi"(%242, %243) : (i32, i32) -> i32
      %245 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %246 = "arith.remsi"(%242, %245) : (i32, i32) -> i32
      %247 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %248 = "arith.muli"(%246, %247) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %249 = "cute.assume"(%248) : (i32) -> !cute.i32<divby 8>
      %250 = "cute.make_int_tuple"(%244, %249) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %251 = "cute.add_offset"(%241, %250) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %252 = "cute.make_view"(%251) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %253 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %254 = "cute.deref_arith_tuple_iter"(%253) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %255:2 = "cute.get_leaves"(%254) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %256 = "cute.get_scalars"(%255#0) : (!cute.int_tuple<"?">) -> i32
      %257 = "cute.get_scalars"(%255#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %258 = "cute.get_layout"(%204) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %259 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %260 = "cute.memref.alloca"(%259) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %261 = "cute.get_iter"(%260) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %262 = "cute.get_iter"(%260) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %263 = "cute.get_layout"(%238) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %264 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %265 = "cute.memref.alloca"(%264) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %266 = "cute.get_iter"(%265) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %267 = "cute.get_iter"(%265) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %268 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %269 = "cute.get_iter"(%178) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %270 = "cute.get_scalars"(%268) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %271 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %272 = "arith.divsi"(%270, %271) : (i32, i32) -> i32
      %273 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %274 = "arith.remsi"(%270, %273) : (i32, i32) -> i32
      %275 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %276 = "arith.muli"(%274, %275) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %277 = "cute.assume"(%276) : (i32) -> !cute.i32<divby 8>
      %278 = "cute.make_int_tuple"(%277) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %279 = "cute.add_offset"(%269, %278) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %280 = "cute.make_view"(%279) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %281 = "cute.get_iter"(%280) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %282 = "cute.get_layout"(%280) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %283 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %284 = "cute.memref.alloca"(%283) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %285 = "cute.get_iter"(%284) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %286 = "cute.get_iter"(%284) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %287 = "cute.get_iter"(%284) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %288 = "cute.make_view"(%287) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_
      %289 = "cute.get_iter"(%288) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %290 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %291 = "cute.size"(%290) <{mode = array<i32: 0, 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %292 = "cute.get_leaves"(%291) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %293 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %294 = "cute.size"(%293) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %295 = "cute.get_leaves"(%294) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %296 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %297 = "cute.size"(%296) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %298 = "cute.get_leaves"(%297) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %299 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %300 = "cute.size"(%299) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %301 = "cute.get_leaves"(%300) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %302 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %303 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %304 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %305 = "cute.memref.alloca"(%304) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %306 = "cute.get_iter"(%305) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %307 = "cute.get_iter"(%305) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %308 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %309 = "cute.get_shape"(%308) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %310:3 = "cute.get_leaves"(%309) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %311 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %312 = "cute.get_shape"(%311) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %313:3 = "cute.get_leaves"(%312) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %314 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %315 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %316 = "cute.crd2idx"(%314, %315) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %317 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %318 = "cute.add_offset"(%317, %316) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %319 = "cute.make_view"(%318) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %320 = "cute.get_iter"(%319) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %321 = "cute.deref_arith_tuple_iter"(%320) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %322:2 = "cute.get_leaves"(%321) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %323 = "cute.get_scalars"(%322#0) : (!cute.int_tuple<"?">) -> i32
      %324 = "cute.get_scalars"(%322#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %325 = "cute.get_iter"(%319) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %326 = "cute.deref_arith_tuple_iter"(%325) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %327:2 = "cute.get_leaves"(%326) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %328 = "cute.get_scalars"(%327#0) : (!cute.int_tuple<"?">) -> i32
      %329 = "cute.get_scalars"(%327#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %330 = "cute.get_iter"(%319) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %331 = "cute.deref_arith_tuple_iter"(%330) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %332:2 = "cute.get_leaves"(%331) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %333 = "cute.get_scalars"(%332#0) : (!cute.int_tuple<"?">) -> i32
      %334 = "cute.get_scalars"(%332#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %335 = "cute.make_coord"(%332#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %336 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %337 = "cute.get_scalars"(%335) : (!cute.coord<"?{div=8}">) -> i32
      %338 = "cute.get_scalars"(%336) : (!cute.coord<"4096">) -> i32
      %339 = "arith.constant"() <{value = true}> : () -> i1
      %340 = "arith.cmpi"(%337, %338) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %341 = "arith.andi"(%339, %340) : (i1, i1) -> i1
      %342 = "arith.extui"(%341) : (i1) -> i8
      %343 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%305, %343, %342) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %344 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %345 = "cute.get_shape"(%344) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %346:3 = "cute.get_leaves"(%345) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %347 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %348 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %349 = "cute.crd2idx"(%347, %348) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %350 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %351 = "cute.add_offset"(%350, %349) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %352 = "cute.make_view"(%351) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %353 = "cute.get_iter"(%352) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %354 = "cute.deref_arith_tuple_iter"(%353) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %355:2 = "cute.get_leaves"(%354) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %356 = "cute.get_scalars"(%355#0) : (!cute.int_tuple<"?">) -> i32
      %357 = "cute.get_scalars"(%355#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %358 = "cute.get_iter"(%352) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %359 = "cute.deref_arith_tuple_iter"(%358) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %360:2 = "cute.get_leaves"(%359) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %361 = "cute.get_scalars"(%360#0) : (!cute.int_tuple<"?">) -> i32
      %362 = "cute.get_scalars"(%360#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %363 = "cute.get_iter"(%352) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %364 = "cute.deref_arith_tuple_iter"(%363) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %365:2 = "cute.get_leaves"(%364) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %366 = "cute.get_scalars"(%365#0) : (!cute.int_tuple<"?">) -> i32
      %367 = "cute.get_scalars"(%365#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %368 = "cute.make_coord"(%365#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %369 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %370 = "cute.get_scalars"(%368) : (!cute.coord<"?{div=8}">) -> i32
      %371 = "cute.get_scalars"(%369) : (!cute.coord<"4096">) -> i32
      %372 = "arith.constant"() <{value = true}> : () -> i1
      %373 = "arith.cmpi"(%370, %371) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %374 = "arith.andi"(%372, %373) : (i1, i1) -> i1
      %375 = "arith.extui"(%374) : (i1) -> i8
      %376 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%305, %376, %375) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %377 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %378 = "cute.get_shape"(%377) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %379:3 = "cute.get_leaves"(%378) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %380 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %381 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %382 = "cute.crd2idx"(%380, %381) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %383 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %384 = "cute.add_offset"(%383, %382) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %385 = "cute.make_view"(%384) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %386 = "cute.get_iter"(%385) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %387 = "cute.deref_arith_tuple_iter"(%386) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %388:2 = "cute.get_leaves"(%387) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %389 = "cute.get_scalars"(%388#0) : (!cute.int_tuple<"?">) -> i32
      %390 = "cute.get_scalars"(%388#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %391 = "cute.get_iter"(%385) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %392 = "cute.deref_arith_tuple_iter"(%391) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %393:2 = "cute.get_leaves"(%392) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %394 = "cute.get_scalars"(%393#0) : (!cute.int_tuple<"?">) -> i32
      %395 = "cute.get_scalars"(%393#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %396 = "cute.get_iter"(%385) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %397 = "cute.deref_arith_tuple_iter"(%396) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %398:2 = "cute.get_leaves"(%397) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %399 = "cute.get_scalars"(%398#0) : (!cute.int_tuple<"?">) -> i32
      %400 = "cute.get_scalars"(%398#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %401 = "cute.make_coord"(%398#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %402 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %403 = "cute.get_scalars"(%401) : (!cute.coord<"?{div=8}">) -> i32
      %404 = "cute.get_scalars"(%402) : (!cute.coord<"4096">) -> i32
      %405 = "arith.constant"() <{value = true}> : () -> i1
      %406 = "arith.cmpi"(%403, %404) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %407 = "arith.andi"(%405, %406) : (i1, i1) -> i1
      %408 = "arith.extui"(%407) : (i1) -> i8
      %409 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%305, %409, %408) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %410 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %411 = "cute.get_shape"(%410) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %412:3 = "cute.get_leaves"(%411) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %413 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %414 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %415 = "cute.crd2idx"(%413, %414) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %416 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %417 = "cute.add_offset"(%416, %415) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %418 = "cute.make_view"(%417) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %419 = "cute.get_iter"(%418) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %420 = "cute.deref_arith_tuple_iter"(%419) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %421:2 = "cute.get_leaves"(%420) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %422 = "cute.get_scalars"(%421#0) : (!cute.int_tuple<"?">) -> i32
      %423 = "cute.get_scalars"(%421#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %424 = "cute.get_iter"(%418) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %425 = "cute.deref_arith_tuple_iter"(%424) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %426:2 = "cute.get_leaves"(%425) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %427 = "cute.get_scalars"(%426#0) : (!cute.int_tuple<"?">) -> i32
      %428 = "cute.get_scalars"(%426#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %429 = "cute.get_iter"(%418) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %430 = "cute.deref_arith_tuple_iter"(%429) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %431:2 = "cute.get_leaves"(%430) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %432 = "cute.get_scalars"(%431#0) : (!cute.int_tuple<"?">) -> i32
      %433 = "cute.get_scalars"(%431#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %434 = "cute.make_coord"(%431#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %435 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %436 = "cute.get_scalars"(%434) : (!cute.coord<"?{div=8}">) -> i32
      %437 = "cute.get_scalars"(%435) : (!cute.coord<"4096">) -> i32
      %438 = "arith.constant"() <{value = true}> : () -> i1
      %439 = "arith.cmpi"(%436, %437) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %440 = "arith.andi"(%438, %439) : (i1, i1) -> i1
      %441 = "arith.extui"(%440) : (i1) -> i8
      %442 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%305, %442, %441) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %443 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %444 = "cute.get_shape"(%443) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %445:3 = "cute.get_leaves"(%444) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %446 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %447 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %448 = "cute.crd2idx"(%446, %447) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %449 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %450 = "cute.add_offset"(%449, %448) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %451 = "cute.make_view"(%450) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %452 = "cute.get_iter"(%451) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %453 = "cute.deref_arith_tuple_iter"(%452) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %454:2 = "cute.get_leaves"(%453) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %455 = "cute.get_scalars"(%454#0) : (!cute.int_tuple<"?">) -> i32
      %456 = "cute.get_scalars"(%454#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %457 = "cute.get_iter"(%451) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %458 = "cute.deref_arith_tuple_iter"(%457) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %459:2 = "cute.get_leaves"(%458) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %460 = "cute.get_scalars"(%459#0) : (!cute.int_tuple<"?">) -> i32
      %461 = "cute.get_scalars"(%459#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %462 = "cute.get_iter"(%451) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %463 = "cute.deref_arith_tuple_iter"(%462) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %464:2 = "cute.get_leaves"(%463) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %465 = "cute.get_scalars"(%464#0) : (!cute.int_tuple<"?">) -> i32
      %466 = "cute.get_scalars"(%464#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %467 = "cute.make_coord"(%464#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %468 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %469 = "cute.get_scalars"(%467) : (!cute.coord<"?{div=8}">) -> i32
      %470 = "cute.get_scalars"(%468) : (!cute.coord<"4096">) -> i32
      %471 = "arith.constant"() <{value = true}> : () -> i1
      %472 = "arith.cmpi"(%469, %470) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %473 = "arith.andi"(%471, %472) : (i1, i1) -> i1
      %474 = "arith.extui"(%473) : (i1) -> i8
      %475 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%305, %475, %474) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %476 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %477 = "cute.get_shape"(%476) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %478:3 = "cute.get_leaves"(%477) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %479 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %480 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %481 = "cute.crd2idx"(%479, %480) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %482 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %483 = "cute.add_offset"(%482, %481) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %484 = "cute.make_view"(%483) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %485 = "cute.get_iter"(%484) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %486 = "cute.deref_arith_tuple_iter"(%485) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %487:2 = "cute.get_leaves"(%486) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %488 = "cute.get_scalars"(%487#0) : (!cute.int_tuple<"?">) -> i32
      %489 = "cute.get_scalars"(%487#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %490 = "cute.get_iter"(%484) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %491 = "cute.deref_arith_tuple_iter"(%490) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %492:2 = "cute.get_leaves"(%491) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %493 = "cute.get_scalars"(%492#0) : (!cute.int_tuple<"?">) -> i32
      %494 = "cute.get_scalars"(%492#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %495 = "cute.get_iter"(%484) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %496 = "cute.deref_arith_tuple_iter"(%495) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %497:2 = "cute.get_leaves"(%496) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %498 = "cute.get_scalars"(%497#0) : (!cute.int_tuple<"?">) -> i32
      %499 = "cute.get_scalars"(%497#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %500 = "cute.make_coord"(%497#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %501 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %502 = "cute.get_scalars"(%500) : (!cute.coord<"?{div=8}">) -> i32
      %503 = "cute.get_scalars"(%501) : (!cute.coord<"4096">) -> i32
      %504 = "arith.constant"() <{value = true}> : () -> i1
      %505 = "arith.cmpi"(%502, %503) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %506 = "arith.andi"(%504, %505) : (i1, i1) -> i1
      %507 = "arith.extui"(%506) : (i1) -> i8
      %508 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%305, %508, %507) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %509 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %510 = "cute.get_shape"(%509) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %511:3 = "cute.get_leaves"(%510) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %512 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %513 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %514 = "cute.crd2idx"(%512, %513) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %515 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %516 = "cute.add_offset"(%515, %514) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %517 = "cute.make_view"(%516) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %518 = "cute.get_iter"(%517) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %519 = "cute.deref_arith_tuple_iter"(%518) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %520:2 = "cute.get_leaves"(%519) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %521 = "cute.get_scalars"(%520#0) : (!cute.int_tuple<"?">) -> i32
      %522 = "cute.get_scalars"(%520#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %523 = "cute.get_iter"(%517) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %524 = "cute.deref_arith_tuple_iter"(%523) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %525:2 = "cute.get_leaves"(%524) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %526 = "cute.get_scalars"(%525#0) : (!cute.int_tuple<"?">) -> i32
      %527 = "cute.get_scalars"(%525#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %528 = "cute.get_iter"(%517) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %529 = "cute.deref_arith_tuple_iter"(%528) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %530:2 = "cute.get_leaves"(%529) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %531 = "cute.get_scalars"(%530#0) : (!cute.int_tuple<"?">) -> i32
      %532 = "cute.get_scalars"(%530#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %533 = "cute.make_coord"(%530#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %534 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %535 = "cute.get_scalars"(%533) : (!cute.coord<"?{div=8}">) -> i32
      %536 = "cute.get_scalars"(%534) : (!cute.coord<"4096">) -> i32
      %537 = "arith.constant"() <{value = true}> : () -> i1
      %538 = "arith.cmpi"(%535, %536) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %539 = "arith.andi"(%537, %538) : (i1, i1) -> i1
      %540 = "arith.extui"(%539) : (i1) -> i8
      %541 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%305, %541, %540) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %542 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %543 = "cute.get_shape"(%542) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %544:3 = "cute.get_leaves"(%543) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %545 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %546 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %547 = "cute.crd2idx"(%545, %546) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %548 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %549 = "cute.add_offset"(%548, %547) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %550 = "cute.make_view"(%549) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %551 = "cute.get_iter"(%550) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %552 = "cute.deref_arith_tuple_iter"(%551) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %553:2 = "cute.get_leaves"(%552) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %554 = "cute.get_scalars"(%553#0) : (!cute.int_tuple<"?">) -> i32
      %555 = "cute.get_scalars"(%553#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %556 = "cute.get_iter"(%550) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %557 = "cute.deref_arith_tuple_iter"(%556) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %558:2 = "cute.get_leaves"(%557) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %559 = "cute.get_scalars"(%558#0) : (!cute.int_tuple<"?">) -> i32
      %560 = "cute.get_scalars"(%558#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %561 = "cute.get_iter"(%550) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %562 = "cute.deref_arith_tuple_iter"(%561) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %563:2 = "cute.get_leaves"(%562) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %564 = "cute.get_scalars"(%563#0) : (!cute.int_tuple<"?">) -> i32
      %565 = "cute.get_scalars"(%563#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %566 = "cute.make_coord"(%563#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %567 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %568 = "cute.get_scalars"(%566) : (!cute.coord<"?{div=8}">) -> i32
      %569 = "cute.get_scalars"(%567) : (!cute.coord<"4096">) -> i32
      %570 = "arith.constant"() <{value = true}> : () -> i1
      %571 = "arith.cmpi"(%568, %569) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %572 = "arith.andi"(%570, %571) : (i1, i1) -> i1
      %573 = "arith.extui"(%572) : (i1) -> i8
      %574 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%305, %574, %573) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %575 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %576 = "cute.get_layout"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %577 = "cute.crd2idx"(%575, %576) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %578 = "cute.get_iter"(%252) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %579 = "cute.add_offset"(%578, %577) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %580 = "cute.make_view"(%579) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %581 = "cute.get_iter"(%580) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %582 = "cute.deref_arith_tuple_iter"(%581) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %583:2 = "cute.get_leaves"(%582) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %584 = "cute.get_scalars"(%583#0) : (!cute.int_tuple<"?">) -> i32
      %585 = "cute.get_scalars"(%583#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %586 = "cute.get_iter"(%580) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %587 = "cute.deref_arith_tuple_iter"(%586) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %588:2 = "cute.get_leaves"(%587) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %589 = "cute.get_scalars"(%588#0) : (!cute.int_tuple<"?">) -> i32
      %590 = "cute.get_scalars"(%588#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %591 = "cute.get_iter"(%580) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %592 = "cute.deref_arith_tuple_iter"(%591) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %593:2 = "cute.get_leaves"(%592) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %594 = "cute.get_scalars"(%593#0) : (!cute.int_tuple<"?">) -> i32
      %595 = "cute.get_scalars"(%593#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %596 = "arith.cmpi"(%594, %62) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%596) ({
        %1569 = "cute.get_layout"(%204) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1570 = "cute.get_shape"(%1569) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1571:4 = "cute.get_leaves"(%1570) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1572 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1573 = "cute.get_shape"(%1572) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1574:4 = "cute.get_leaves"(%1573) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1575 = "cute.get_layout"(%204) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1576 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1577 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1578 = "cute.append_to_rank"(%1575, %1577) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1579 = "cute.make_view"(%205, %1578) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %1580 = "cute.get_iter"(%1579) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1581 = "cute.get_layout"(%1579) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1582 = "cute.get_shape"(%1581) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1583:4 = "cute.get_leaves"(%1582) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1584 = "cute.get_layout"(%1579) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1585 = "cute.get_shape"(%1584) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1586:4 = "cute.get_leaves"(%1585) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1587 = "cute.get_iter"(%1579) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1588 = "cute.make_view"(%1587) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %1589 = "cute.get_iter"(%1588) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1590 = "cute.get_iter"(%1588) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1591 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1592 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1593 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1594 = "cute.append_to_rank"(%1591, %1593) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1595 = "cute.make_view"(%222, %1594) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_smem_bf16_1
        %1596 = "cute.get_iter"(%1595) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %1597 = "cute.get_layout"(%1595) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1598 = "cute.get_shape"(%1597) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1599:4 = "cute.get_leaves"(%1598) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1600 = "cute.get_layout"(%1595) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1601 = "cute.get_shape"(%1600) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1602:4 = "cute.get_leaves"(%1601) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1603 = "cute.get_iter"(%1595) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %1604 = "cute.make_view"(%1603) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_2
        %1605 = "cute.get_iter"(%1604) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1606 = "cute.get_iter"(%1604) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1607 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1608 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1609 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1610 = "cute.append_to_rank"(%1607, %1609) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1611 = "cute.make_view"(%307, %1610) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1612 = "cute.get_iter"(%1611) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1613 = "cute.get_layout"(%1611) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1614 = "cute.get_shape"(%1613) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1615:3 = "cute.get_leaves"(%1614) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1616 = "cute.get_layout"(%1611) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1617 = "cute.get_shape"(%1616) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1618:3 = "cute.get_leaves"(%1617) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1619 = "cute.get_iter"(%1611) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1620 = "cute.make_view"(%1619) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1621 = "cute.get_iter"(%1620) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1622 = "cute.get_iter"(%1620) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1623 = "cute.get_layout"(%1588) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1624 = "cute.get_shape"(%1623) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1625:4 = "cute.get_leaves"(%1624) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1626 = "cute.get_layout"(%1604) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1627 = "cute.get_shape"(%1626) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1628:4 = "cute.get_leaves"(%1627) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1629 = "cute.get_layout"(%1588) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1630 = "cute.size"(%1629) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1631 = "cute.get_leaves"(%1630) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1632 = "cute.get_layout"(%1604) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1633 = "cute.size"(%1632) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1634 = "cute.get_leaves"(%1633) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1635 = "cute.static"() : () -> !cute.layout<"1:0">
        %1636 = "cute.get_iter"(%1588) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1637 = "cute.get_iter"(%1604) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1638 = "cute.get_layout"(%1588) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1639 = "cute.get_layout"(%1604) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1640 = "cute.append_to_rank"(%1638, %1635) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1641 = "cute.append_to_rank"(%1639, %1635) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1642 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1643 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1644 = "cute.get_iter"(%1620) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1645 = "cute.get_layout"(%1620) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1646 = "cute.append_to_rank"(%1645, %1635) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1647 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %1648 = "cute.size"(%1642) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
        %1649 = "cute.get_scalars"(%1648) : (!cute.int_tuple<"1">) -> i32
        %1650 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1651 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1650, %1649, %1651) ({
        ^bb0(%arg14: i32):
          %1652 = "cute.make_coord"(%arg14) : (i32) -> !cute.coord<"(_,?)">
          %1653 = "cute.get_scalars"(%1652) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1654 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,512))">
          %1655 = "cute.crd2idx"(%1652, %1642) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1656 = "cute.add_offset"(%1636, %1655) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %1657 = "cute.make_view"(%1656, %1654) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %1658 = "cute.get_scalars"(%1652) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1659 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,512))">
          %1660 = "cute.crd2idx"(%1652, %1643) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1661 = "cute.add_offset"(%1637, %1660) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %1662 = "cute.make_view"(%1661, %1659) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_smem_bf16_3
          %1663 = "cute.get_scalars"(%1652) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1664 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
          %1665 = "cute.crd2idx"(%1652, %1647) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %1666 = "cute.add_offset"(%1644, %1665) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1667 = "cute.make_view"(%1666, %1664) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          %1668 = "cute.get_iter"(%1657) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
          %1669 = "cute.get_iter"(%1662) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %1670 = "cute.get_iter"(%1667) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
          %1671 = "builtin.unrealized_conversion_cast"(%1670) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1672 = "llvm.load"(%1671) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1673 = "llvm.trunc"(%1672) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1674 = "cute.recast_iter"(%1668) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1675 = "cute.recast_iter"(%1669) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1675, %1674, %1673) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1676 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"512">
          %1677 = "cute.add_offset"(%1668, %1676) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %1678 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"512">
          %1679 = "cute.add_offset"(%1669, %1678) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
          %1680 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %1681 = "cute.add_offset"(%1670, %1680) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %1682 = "builtin.unrealized_conversion_cast"(%1681) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1683 = "llvm.load"(%1682) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1684 = "llvm.trunc"(%1683) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1685 = "cute.recast_iter"(%1677) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1686 = "cute.recast_iter"(%1679) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1686, %1685, %1684) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1687 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1024">
          %1688 = "cute.add_offset"(%1668, %1687) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %1689 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1024">
          %1690 = "cute.add_offset"(%1669, %1689) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %1691 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %1692 = "cute.add_offset"(%1670, %1691) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %1693 = "builtin.unrealized_conversion_cast"(%1692) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1694 = "llvm.load"(%1693) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1695 = "llvm.trunc"(%1694) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1696 = "cute.recast_iter"(%1688) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1697 = "cute.recast_iter"(%1690) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1697, %1696, %1695) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1698 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1536">
          %1699 = "cute.add_offset"(%1668, %1698) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %1700 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1536">
          %1701 = "cute.add_offset"(%1669, %1700) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
          %1702 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %1703 = "cute.add_offset"(%1670, %1702) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %1704 = "builtin.unrealized_conversion_cast"(%1703) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1705 = "llvm.load"(%1704) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1706 = "llvm.trunc"(%1705) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1707 = "cute.recast_iter"(%1699) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1708 = "cute.recast_iter"(%1701) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1708, %1707, %1706) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1709 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2048">
          %1710 = "cute.add_offset"(%1668, %1709) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %1711 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2048">
          %1712 = "cute.add_offset"(%1669, %1711) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %1713 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
          %1714 = "cute.add_offset"(%1670, %1713) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %1715 = "builtin.unrealized_conversion_cast"(%1714) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1716 = "llvm.load"(%1715) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1717 = "llvm.trunc"(%1716) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1718 = "cute.recast_iter"(%1710) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1719 = "cute.recast_iter"(%1712) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1719, %1718, %1717) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1720 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2560">
          %1721 = "cute.add_offset"(%1668, %1720) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %1722 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2560">
          %1723 = "cute.add_offset"(%1669, %1722) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
          %1724 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
          %1725 = "cute.add_offset"(%1670, %1724) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %1726 = "builtin.unrealized_conversion_cast"(%1725) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1727 = "llvm.load"(%1726) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1728 = "llvm.trunc"(%1727) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1729 = "cute.recast_iter"(%1721) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1730 = "cute.recast_iter"(%1723) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1730, %1729, %1728) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1731 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3072">
          %1732 = "cute.add_offset"(%1668, %1731) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %1733 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3072">
          %1734 = "cute.add_offset"(%1669, %1733) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %1735 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
          %1736 = "cute.add_offset"(%1670, %1735) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %1737 = "builtin.unrealized_conversion_cast"(%1736) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1738 = "llvm.load"(%1737) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1739 = "llvm.trunc"(%1738) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1740 = "cute.recast_iter"(%1732) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1741 = "cute.recast_iter"(%1734) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1741, %1740, %1739) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %1742 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3584">
          %1743 = "cute.add_offset"(%1668, %1742) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %1744 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3584">
          %1745 = "cute.add_offset"(%1669, %1744) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
          %1746 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
          %1747 = "cute.add_offset"(%1670, %1746) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %1748 = "builtin.unrealized_conversion_cast"(%1747) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1749 = "llvm.load"(%1748) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1750 = "llvm.trunc"(%1749) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1751 = "cute.recast_iter"(%1743) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1752 = "cute.recast_iter"(%1745) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1752, %1751, %1750) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %597 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %598 = "cute.get_iter"(%156) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %599 = "cute.get_scalars"(%597) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %600 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %601 = "arith.divsi"(%599, %600) : (i32, i32) -> i32
      %602 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %603 = "arith.remsi"(%599, %602) : (i32, i32) -> i32
      %604 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %605 = "arith.muli"(%603, %604) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %606 = "cute.assume"(%605) : (i32) -> !cute.i32<divby 8>
      %607 = "cute.make_int_tuple"(%601, %606) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %608 = "cute.add_offset"(%598, %607) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %609 = "cute.make_view"(%608) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %610 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %611 = "cute.deref_arith_tuple_iter"(%610) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %612:2 = "cute.get_leaves"(%611) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %613 = "cute.get_scalars"(%612#0) : (!cute.int_tuple<"?">) -> i32
      %614 = "cute.get_scalars"(%612#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %615 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %616 = "cute.size"(%615) <{mode = array<i32: 0, 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %617 = "cute.get_leaves"(%616) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %618 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %619 = "cute.size"(%618) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %620 = "cute.get_leaves"(%619) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %621 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %622 = "cute.size"(%621) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %623 = "cute.get_leaves"(%622) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %624 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %625 = "cute.size"(%624) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %626 = "cute.get_leaves"(%625) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %627 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %628 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %629 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %630 = "cute.memref.alloca"(%629) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %631 = "cute.get_iter"(%630) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %632 = "cute.get_iter"(%630) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %633 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %634 = "cute.get_shape"(%633) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %635:3 = "cute.get_leaves"(%634) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %636 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %637 = "cute.get_shape"(%636) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %638:3 = "cute.get_leaves"(%637) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %639 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %640 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %641 = "cute.crd2idx"(%639, %640) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %642 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %643 = "cute.add_offset"(%642, %641) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %644 = "cute.make_view"(%643) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %645 = "cute.get_iter"(%644) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %646 = "cute.deref_arith_tuple_iter"(%645) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %647:2 = "cute.get_leaves"(%646) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %648 = "cute.get_scalars"(%647#0) : (!cute.int_tuple<"?">) -> i32
      %649 = "cute.get_scalars"(%647#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %650 = "cute.get_iter"(%644) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %651 = "cute.deref_arith_tuple_iter"(%650) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %652:2 = "cute.get_leaves"(%651) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %653 = "cute.get_scalars"(%652#0) : (!cute.int_tuple<"?">) -> i32
      %654 = "cute.get_scalars"(%652#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %655 = "cute.get_iter"(%644) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %656 = "cute.deref_arith_tuple_iter"(%655) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %657:2 = "cute.get_leaves"(%656) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %658 = "cute.get_scalars"(%657#0) : (!cute.int_tuple<"?">) -> i32
      %659 = "cute.get_scalars"(%657#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %660 = "cute.make_coord"(%657#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %661 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %662 = "cute.get_scalars"(%660) : (!cute.coord<"?{div=8}">) -> i32
      %663 = "cute.get_scalars"(%661) : (!cute.coord<"4096">) -> i32
      %664 = "arith.constant"() <{value = true}> : () -> i1
      %665 = "arith.cmpi"(%662, %663) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %666 = "arith.andi"(%664, %665) : (i1, i1) -> i1
      %667 = "arith.extui"(%666) : (i1) -> i8
      %668 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%630, %668, %667) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %669 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %670 = "cute.get_shape"(%669) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %671:3 = "cute.get_leaves"(%670) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %672 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %673 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %674 = "cute.crd2idx"(%672, %673) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %675 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %676 = "cute.add_offset"(%675, %674) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %677 = "cute.make_view"(%676) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %678 = "cute.get_iter"(%677) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %679 = "cute.deref_arith_tuple_iter"(%678) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %680:2 = "cute.get_leaves"(%679) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %681 = "cute.get_scalars"(%680#0) : (!cute.int_tuple<"?">) -> i32
      %682 = "cute.get_scalars"(%680#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %683 = "cute.get_iter"(%677) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %684 = "cute.deref_arith_tuple_iter"(%683) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %685:2 = "cute.get_leaves"(%684) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %686 = "cute.get_scalars"(%685#0) : (!cute.int_tuple<"?">) -> i32
      %687 = "cute.get_scalars"(%685#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %688 = "cute.get_iter"(%677) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %689 = "cute.deref_arith_tuple_iter"(%688) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %690:2 = "cute.get_leaves"(%689) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %691 = "cute.get_scalars"(%690#0) : (!cute.int_tuple<"?">) -> i32
      %692 = "cute.get_scalars"(%690#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %693 = "cute.make_coord"(%690#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %694 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %695 = "cute.get_scalars"(%693) : (!cute.coord<"?{div=8}">) -> i32
      %696 = "cute.get_scalars"(%694) : (!cute.coord<"4096">) -> i32
      %697 = "arith.constant"() <{value = true}> : () -> i1
      %698 = "arith.cmpi"(%695, %696) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %699 = "arith.andi"(%697, %698) : (i1, i1) -> i1
      %700 = "arith.extui"(%699) : (i1) -> i8
      %701 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%630, %701, %700) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %702 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %703 = "cute.get_shape"(%702) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %704:3 = "cute.get_leaves"(%703) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %705 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %706 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %707 = "cute.crd2idx"(%705, %706) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %708 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %709 = "cute.add_offset"(%708, %707) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %710 = "cute.make_view"(%709) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %711 = "cute.get_iter"(%710) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %712 = "cute.deref_arith_tuple_iter"(%711) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %713:2 = "cute.get_leaves"(%712) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %714 = "cute.get_scalars"(%713#0) : (!cute.int_tuple<"?">) -> i32
      %715 = "cute.get_scalars"(%713#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %716 = "cute.get_iter"(%710) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %717 = "cute.deref_arith_tuple_iter"(%716) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %718:2 = "cute.get_leaves"(%717) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %719 = "cute.get_scalars"(%718#0) : (!cute.int_tuple<"?">) -> i32
      %720 = "cute.get_scalars"(%718#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %721 = "cute.get_iter"(%710) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %722 = "cute.deref_arith_tuple_iter"(%721) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %723:2 = "cute.get_leaves"(%722) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %724 = "cute.get_scalars"(%723#0) : (!cute.int_tuple<"?">) -> i32
      %725 = "cute.get_scalars"(%723#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %726 = "cute.make_coord"(%723#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %727 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %728 = "cute.get_scalars"(%726) : (!cute.coord<"?{div=8}">) -> i32
      %729 = "cute.get_scalars"(%727) : (!cute.coord<"4096">) -> i32
      %730 = "arith.constant"() <{value = true}> : () -> i1
      %731 = "arith.cmpi"(%728, %729) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %732 = "arith.andi"(%730, %731) : (i1, i1) -> i1
      %733 = "arith.extui"(%732) : (i1) -> i8
      %734 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%630, %734, %733) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %735 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %736 = "cute.get_shape"(%735) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %737:3 = "cute.get_leaves"(%736) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %738 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %739 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %740 = "cute.crd2idx"(%738, %739) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %741 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %742 = "cute.add_offset"(%741, %740) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %743 = "cute.make_view"(%742) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %744 = "cute.get_iter"(%743) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %745 = "cute.deref_arith_tuple_iter"(%744) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %746:2 = "cute.get_leaves"(%745) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %747 = "cute.get_scalars"(%746#0) : (!cute.int_tuple<"?">) -> i32
      %748 = "cute.get_scalars"(%746#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %749 = "cute.get_iter"(%743) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %750 = "cute.deref_arith_tuple_iter"(%749) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %751:2 = "cute.get_leaves"(%750) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %752 = "cute.get_scalars"(%751#0) : (!cute.int_tuple<"?">) -> i32
      %753 = "cute.get_scalars"(%751#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %754 = "cute.get_iter"(%743) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %755 = "cute.deref_arith_tuple_iter"(%754) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %756:2 = "cute.get_leaves"(%755) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %757 = "cute.get_scalars"(%756#0) : (!cute.int_tuple<"?">) -> i32
      %758 = "cute.get_scalars"(%756#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %759 = "cute.make_coord"(%756#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %760 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %761 = "cute.get_scalars"(%759) : (!cute.coord<"?{div=8}">) -> i32
      %762 = "cute.get_scalars"(%760) : (!cute.coord<"4096">) -> i32
      %763 = "arith.constant"() <{value = true}> : () -> i1
      %764 = "arith.cmpi"(%761, %762) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %765 = "arith.andi"(%763, %764) : (i1, i1) -> i1
      %766 = "arith.extui"(%765) : (i1) -> i8
      %767 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%630, %767, %766) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %768 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %769 = "cute.get_shape"(%768) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %770:3 = "cute.get_leaves"(%769) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %771 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %772 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %773 = "cute.crd2idx"(%771, %772) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %774 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %775 = "cute.add_offset"(%774, %773) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %776 = "cute.make_view"(%775) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %777 = "cute.get_iter"(%776) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %778 = "cute.deref_arith_tuple_iter"(%777) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %779:2 = "cute.get_leaves"(%778) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %780 = "cute.get_scalars"(%779#0) : (!cute.int_tuple<"?">) -> i32
      %781 = "cute.get_scalars"(%779#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %782 = "cute.get_iter"(%776) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %783 = "cute.deref_arith_tuple_iter"(%782) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %784:2 = "cute.get_leaves"(%783) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %785 = "cute.get_scalars"(%784#0) : (!cute.int_tuple<"?">) -> i32
      %786 = "cute.get_scalars"(%784#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %787 = "cute.get_iter"(%776) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %788 = "cute.deref_arith_tuple_iter"(%787) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %789:2 = "cute.get_leaves"(%788) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %790 = "cute.get_scalars"(%789#0) : (!cute.int_tuple<"?">) -> i32
      %791 = "cute.get_scalars"(%789#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %792 = "cute.make_coord"(%789#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %793 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %794 = "cute.get_scalars"(%792) : (!cute.coord<"?{div=8}">) -> i32
      %795 = "cute.get_scalars"(%793) : (!cute.coord<"4096">) -> i32
      %796 = "arith.constant"() <{value = true}> : () -> i1
      %797 = "arith.cmpi"(%794, %795) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %798 = "arith.andi"(%796, %797) : (i1, i1) -> i1
      %799 = "arith.extui"(%798) : (i1) -> i8
      %800 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%630, %800, %799) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %801 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %802 = "cute.get_shape"(%801) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %803:3 = "cute.get_leaves"(%802) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %804 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %805 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %806 = "cute.crd2idx"(%804, %805) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %807 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %808 = "cute.add_offset"(%807, %806) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %809 = "cute.make_view"(%808) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %810 = "cute.get_iter"(%809) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %811 = "cute.deref_arith_tuple_iter"(%810) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %812:2 = "cute.get_leaves"(%811) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %813 = "cute.get_scalars"(%812#0) : (!cute.int_tuple<"?">) -> i32
      %814 = "cute.get_scalars"(%812#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %815 = "cute.get_iter"(%809) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %816 = "cute.deref_arith_tuple_iter"(%815) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %817:2 = "cute.get_leaves"(%816) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %818 = "cute.get_scalars"(%817#0) : (!cute.int_tuple<"?">) -> i32
      %819 = "cute.get_scalars"(%817#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %820 = "cute.get_iter"(%809) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %821 = "cute.deref_arith_tuple_iter"(%820) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %822:2 = "cute.get_leaves"(%821) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %823 = "cute.get_scalars"(%822#0) : (!cute.int_tuple<"?">) -> i32
      %824 = "cute.get_scalars"(%822#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %825 = "cute.make_coord"(%822#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %826 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %827 = "cute.get_scalars"(%825) : (!cute.coord<"?{div=8}">) -> i32
      %828 = "cute.get_scalars"(%826) : (!cute.coord<"4096">) -> i32
      %829 = "arith.constant"() <{value = true}> : () -> i1
      %830 = "arith.cmpi"(%827, %828) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %831 = "arith.andi"(%829, %830) : (i1, i1) -> i1
      %832 = "arith.extui"(%831) : (i1) -> i8
      %833 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%630, %833, %832) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %834 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %835 = "cute.get_shape"(%834) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %836:3 = "cute.get_leaves"(%835) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %837 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %838 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %839 = "cute.crd2idx"(%837, %838) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %840 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %841 = "cute.add_offset"(%840, %839) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %842 = "cute.make_view"(%841) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %843 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %844 = "cute.deref_arith_tuple_iter"(%843) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %845:2 = "cute.get_leaves"(%844) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %846 = "cute.get_scalars"(%845#0) : (!cute.int_tuple<"?">) -> i32
      %847 = "cute.get_scalars"(%845#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %848 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %849 = "cute.deref_arith_tuple_iter"(%848) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %850:2 = "cute.get_leaves"(%849) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %851 = "cute.get_scalars"(%850#0) : (!cute.int_tuple<"?">) -> i32
      %852 = "cute.get_scalars"(%850#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %853 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %854 = "cute.deref_arith_tuple_iter"(%853) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %855:2 = "cute.get_leaves"(%854) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %856 = "cute.get_scalars"(%855#0) : (!cute.int_tuple<"?">) -> i32
      %857 = "cute.get_scalars"(%855#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %858 = "cute.make_coord"(%855#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %859 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %860 = "cute.get_scalars"(%858) : (!cute.coord<"?{div=8}">) -> i32
      %861 = "cute.get_scalars"(%859) : (!cute.coord<"4096">) -> i32
      %862 = "arith.constant"() <{value = true}> : () -> i1
      %863 = "arith.cmpi"(%860, %861) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %864 = "arith.andi"(%862, %863) : (i1, i1) -> i1
      %865 = "arith.extui"(%864) : (i1) -> i8
      %866 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%630, %866, %865) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %867 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %868 = "cute.get_shape"(%867) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %869:3 = "cute.get_leaves"(%868) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %870 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %871 = "cute.get_layout"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %872 = "cute.crd2idx"(%870, %871) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %873 = "cute.get_iter"(%609) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %874 = "cute.add_offset"(%873, %872) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %875 = "cute.make_view"(%874) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %876 = "cute.get_iter"(%875) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %877 = "cute.deref_arith_tuple_iter"(%876) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %878:2 = "cute.get_leaves"(%877) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %879 = "cute.get_scalars"(%878#0) : (!cute.int_tuple<"?">) -> i32
      %880 = "cute.get_scalars"(%878#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %881 = "cute.get_iter"(%875) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %882 = "cute.deref_arith_tuple_iter"(%881) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %883:2 = "cute.get_leaves"(%882) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %884 = "cute.get_scalars"(%883#0) : (!cute.int_tuple<"?">) -> i32
      %885 = "cute.get_scalars"(%883#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %886 = "cute.get_iter"(%875) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %887 = "cute.deref_arith_tuple_iter"(%886) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %888:2 = "cute.get_leaves"(%887) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %889 = "cute.get_scalars"(%888#0) : (!cute.int_tuple<"?">) -> i32
      %890 = "cute.get_scalars"(%888#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %891 = "cute.make_coord"(%888#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %892 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %893 = "cute.get_scalars"(%891) : (!cute.coord<"?{div=8}">) -> i32
      %894 = "cute.get_scalars"(%892) : (!cute.coord<"4096">) -> i32
      %895 = "arith.constant"() <{value = true}> : () -> i1
      %896 = "arith.cmpi"(%893, %894) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %897 = "arith.andi"(%895, %896) : (i1, i1) -> i1
      %898 = "arith.extui"(%897) : (i1) -> i8
      %899 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%630, %899, %898) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %900 = "cute.get_layout"(%280) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %901 = "cute.get_shape"(%900) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %902:4 = "cute.get_leaves"(%901) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %903 = "cute.get_layout"(%284) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %904 = "cute.get_shape"(%903) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %905:4 = "cute.get_leaves"(%904) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %906 = "cute.get_layout"(%280) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %907 = "cute.make_shape"() : () -> !cute.shape<"1">
      %908 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %909 = "cute.append_to_rank"(%906, %908) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %910 = "cute.make_view"(%281, %909) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
      %911 = "cute.get_iter"(%910) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %912 = "cute.get_layout"(%910) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %913 = "cute.get_shape"(%912) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %914:4 = "cute.get_leaves"(%913) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %915 = "cute.get_layout"(%910) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %916 = "cute.get_shape"(%915) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %917:4 = "cute.get_leaves"(%916) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %918 = "cute.get_iter"(%910) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %919 = "cute.make_view"(%918) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
      %920 = "cute.get_iter"(%919) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %921 = "cute.get_iter"(%919) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %922 = "cute.get_layout"(%284) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %923 = "cute.make_shape"() : () -> !cute.shape<"1">
      %924 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %925 = "cute.append_to_rank"(%922, %924) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %926 = "cute.make_view"(%286, %925) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %927 = "cute.get_iter"(%926) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %928 = "cute.get_layout"(%926) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %929 = "cute.get_shape"(%928) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %930:4 = "cute.get_leaves"(%929) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %931 = "cute.get_layout"(%926) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %932 = "cute.get_shape"(%931) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %933:4 = "cute.get_leaves"(%932) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %934 = "cute.get_iter"(%926) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %935 = "cute.make_view"(%934) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
      %936 = "cute.get_iter"(%935) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %937 = "cute.get_iter"(%935) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %938 = "cute.get_layout"(%630) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %939 = "cute.make_shape"() : () -> !cute.shape<"1">
      %940 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %941 = "cute.append_to_rank"(%938, %940) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %942 = "cute.make_view"(%632, %941) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %943 = "cute.get_iter"(%942) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %944 = "cute.get_layout"(%942) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %945 = "cute.get_shape"(%944) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %946:3 = "cute.get_leaves"(%945) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %947 = "cute.get_layout"(%942) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %948 = "cute.get_shape"(%947) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %949:3 = "cute.get_leaves"(%948) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %950 = "cute.get_iter"(%942) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %951 = "cute.make_view"(%950) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %952 = "cute.get_iter"(%951) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %953 = "cute.get_iter"(%951) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %954 = "cute.get_layout"(%919) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %955 = "cute.get_shape"(%954) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %956:4 = "cute.get_leaves"(%955) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %957 = "cute.get_layout"(%935) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %958 = "cute.get_shape"(%957) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %959:4 = "cute.get_leaves"(%958) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %960 = "cute.get_layout"(%919) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %961 = "cute.size"(%960) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
      %962 = "cute.get_leaves"(%961) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %963 = "cute.get_layout"(%935) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %964 = "cute.size"(%963) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
      %965 = "cute.get_leaves"(%964) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %966 = "cute.static"() : () -> !cute.layout<"1:0">
      %967 = "cute.get_iter"(%919) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %968 = "cute.get_iter"(%935) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %969 = "cute.get_layout"(%919) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %970 = "cute.get_layout"(%935) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %971 = "cute.append_to_rank"(%969, %966) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %972 = "cute.append_to_rank"(%970, %966) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %973 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
      %974 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
      %975 = "cute.get_iter"(%951) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %976 = "cute.get_layout"(%951) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
      %977 = "cute.append_to_rank"(%976, %966) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
      %978 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %979 = "cute.size"(%973) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
      %980 = "cute.get_scalars"(%979) : (!cute.int_tuple<"1">) -> i32
      %981 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %982 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%981, %980, %982) ({
      ^bb0(%arg13: i32):
        %1452 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"(_,?)">
        %1453 = "cute.get_scalars"(%1452) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1454 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,512))">
        %1455 = "cute.crd2idx"(%1452, %973) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
        %1456 = "cute.add_offset"(%967, %1455) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %1457 = "cute.make_view"(%1456, %1454) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
        %1458 = "cute.get_scalars"(%1452) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1459 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,8))">
        %1460 = "cute.crd2idx"(%1452, %974) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
        %1461 = "cute.add_offset"(%968, %1460) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %1462 = "cute.make_view"(%1461, %1459) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
        %1463 = "cute.get_scalars"(%1452) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1464 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
        %1465 = "cute.crd2idx"(%1452, %978) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %1466 = "cute.add_offset"(%975, %1465) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %1467 = "cute.make_view"(%1466, %1464) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
        %1468 = "cute.get_iter"(%1457) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %1469 = "cute.get_iter"(%1462) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
        %1470 = "cute.get_iter"(%1467) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
        %1471 = "builtin.unrealized_conversion_cast"(%1470) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1472 = "llvm.load"(%1471) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1473 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1474 = "llvm.icmp"(%1472, %1473) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1474) ({
          %1566 = "builtin.unrealized_conversion_cast"(%1468) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1567 = "builtin.unrealized_conversion_cast"(%1469) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %1568 = "llvm.load"(%1566) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1568, %1567) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1475 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
        %1476 = "cute.add_offset"(%1470, %1475) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %1477 = "builtin.unrealized_conversion_cast"(%1476) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1478 = "llvm.load"(%1477) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1479 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1480 = "llvm.icmp"(%1478, %1479) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1480) ({
          %1559 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"512">
          %1560 = "cute.add_offset"(%1468, %1559) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %1561 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"8">
          %1562 = "cute.add_offset"(%1469, %1561) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %1563 = "builtin.unrealized_conversion_cast"(%1560) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1564 = "builtin.unrealized_conversion_cast"(%1562) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %1565 = "llvm.load"(%1563) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1565, %1564) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1481 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
        %1482 = "cute.add_offset"(%1470, %1481) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %1483 = "builtin.unrealized_conversion_cast"(%1482) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1484 = "llvm.load"(%1483) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1485 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1486 = "llvm.icmp"(%1484, %1485) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1486) ({
          %1552 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1024">
          %1553 = "cute.add_offset"(%1468, %1552) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %1554 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
          %1555 = "cute.add_offset"(%1469, %1554) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %1556 = "builtin.unrealized_conversion_cast"(%1553) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1557 = "builtin.unrealized_conversion_cast"(%1555) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %1558 = "llvm.load"(%1556) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1558, %1557) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1487 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
        %1488 = "cute.add_offset"(%1470, %1487) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %1489 = "builtin.unrealized_conversion_cast"(%1488) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1490 = "llvm.load"(%1489) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1491 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1492 = "llvm.icmp"(%1490, %1491) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1492) ({
          %1545 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1536">
          %1546 = "cute.add_offset"(%1468, %1545) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %1547 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"24">
          %1548 = "cute.add_offset"(%1469, %1547) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %1549 = "builtin.unrealized_conversion_cast"(%1546) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1550 = "builtin.unrealized_conversion_cast"(%1548) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %1551 = "llvm.load"(%1549) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1551, %1550) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1493 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %1494 = "cute.add_offset"(%1470, %1493) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %1495 = "builtin.unrealized_conversion_cast"(%1494) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1496 = "llvm.load"(%1495) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1497 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1498 = "llvm.icmp"(%1496, %1497) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1498) ({
          %1538 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2048">
          %1539 = "cute.add_offset"(%1468, %1538) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %1540 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
          %1541 = "cute.add_offset"(%1469, %1540) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %1542 = "builtin.unrealized_conversion_cast"(%1539) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1543 = "builtin.unrealized_conversion_cast"(%1541) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %1544 = "llvm.load"(%1542) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1544, %1543) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1499 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
        %1500 = "cute.add_offset"(%1470, %1499) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %1501 = "builtin.unrealized_conversion_cast"(%1500) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1502 = "llvm.load"(%1501) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1503 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1504 = "llvm.icmp"(%1502, %1503) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1504) ({
          %1531 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2560">
          %1532 = "cute.add_offset"(%1468, %1531) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %1533 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"40">
          %1534 = "cute.add_offset"(%1469, %1533) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %1535 = "builtin.unrealized_conversion_cast"(%1532) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1536 = "builtin.unrealized_conversion_cast"(%1534) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %1537 = "llvm.load"(%1535) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1537, %1536) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1505 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
        %1506 = "cute.add_offset"(%1470, %1505) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %1507 = "builtin.unrealized_conversion_cast"(%1506) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1508 = "llvm.load"(%1507) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1509 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1510 = "llvm.icmp"(%1508, %1509) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1510) ({
          %1524 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3072">
          %1525 = "cute.add_offset"(%1468, %1524) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %1526 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"48">
          %1527 = "cute.add_offset"(%1469, %1526) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %1528 = "builtin.unrealized_conversion_cast"(%1525) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1529 = "builtin.unrealized_conversion_cast"(%1527) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %1530 = "llvm.load"(%1528) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1530, %1529) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1511 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
        %1512 = "cute.add_offset"(%1470, %1511) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %1513 = "builtin.unrealized_conversion_cast"(%1512) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1514 = "llvm.load"(%1513) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1515 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %1516 = "llvm.icmp"(%1514, %1515) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%1516) ({
          %1517 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3584">
          %1518 = "cute.add_offset"(%1468, %1517) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %1519 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"56">
          %1520 = "cute.add_offset"(%1469, %1519) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %1521 = "builtin.unrealized_conversion_cast"(%1518) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %1522 = "builtin.unrealized_conversion_cast"(%1520) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %1523 = "llvm.load"(%1521) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%1523, %1522) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %983 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %984 = "cute.get_shape"(%983) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %985:4 = "cute.get_leaves"(%984) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %986 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %987 = "cute.get_shape"(%986) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %988:4 = "cute.get_leaves"(%987) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %989 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %990 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %991 = "cute.right_inverse"(%990) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %992 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,8):(1,512)">
      %993 = "cute.coalesce"(%992) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %994 = "cute.get_shape"(%993) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %995:2 = "cute.get_leaves"(%994) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %996 = "cute.get_stride"(%993) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %997:2 = "cute.get_leaves"(%996) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %998 = "cute.get_shape"(%993) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %999:2 = "cute.get_leaves"(%998) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1000 = "cute.get_shape"(%993) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %1001:2 = "cute.get_leaves"(%1000) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1002 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1003 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1004 = "cute.size"(%1003) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %1005 = "cute.get_leaves"(%1004) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %1006 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %1007 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1008 = "cute.get_iter"(%221) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %1009 = "cute.make_view"(%1008) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1010 = "cute.get_iter"(%1009) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1011 = "cute.get_iter"(%1009) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1012 = "cute.get_iter"(%260) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %1013 = "cute.make_view"(%1012) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1014 = "cute.get_iter"(%1013) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1015 = "cute.get_iter"(%1013) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1016 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1017 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1018 = "cute.get_iter"(%1009) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1019 = "cute.make_view"(%1018) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1020 = "cute.get_iter"(%1019) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1021 = "cute.get_iter"(%1019) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1022 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1023 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1024 = "cute.get_iter"(%1013) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1025 = "cute.make_view"(%1024) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1026 = "cute.get_iter"(%1025) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1027 = "cute.get_iter"(%1025) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1028 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %1029 = "cute.static"() : () -> !cute.layout<"1:0">
      %1030 = "cute.get_iter"(%1019) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1031 = "cute.get_iter"(%1025) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1032 = "cute.get_layout"(%1019) : (!memref_smem_bf16_4) -> !cute.layout<"(8,8):(1,512)">
      %1033 = "cute.get_layout"(%1025) : (!memref_rmem_bf16_3) -> !cute.layout<"(8,8):(1,8)">
      %1034 = "cute.append_to_rank"(%1032, %1029) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,512)">
      %1035 = "cute.append_to_rank"(%1033, %1029) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,8)">
      %1036 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(512))">
      %1037 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(8))">
      %1038 = "cute.size"(%1036) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %1039 = "cute.get_scalars"(%1038) : (!cute.int_tuple<"8">) -> i32
      %1040 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1041 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%1040, %1039, %1041) ({
      ^bb0(%arg12: i32):
        %1436 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"(_,?)">
        %1437 = "cute.get_scalars"(%1436) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1438 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
        %1439 = "cute.crd2idx"(%1436, %1036) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %1440 = "cute.add_offset"(%1030, %1439) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %1441 = "cute.make_view"(%1440, %1438) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %1442 = "cute.get_scalars"(%1436) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1443 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
        %1444 = "cute.crd2idx"(%1436, %1037) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %1445 = "cute.add_offset"(%1031, %1444) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1446 = "cute.make_view"(%1445, %1443) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        %1447 = "cute.get_iter"(%1441) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
        %1448 = "cute.get_iter"(%1446) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<16>>
        %1449 = "builtin.unrealized_conversion_cast"(%1447) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %1450 = "builtin.unrealized_conversion_cast"(%1448) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %1451 = "llvm.load"(%1449) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%1451, %1450) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %1042 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1043 = "cute.get_shape"(%1042) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1044:4 = "cute.get_leaves"(%1043) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1045 = "cute.memref.load_vec"(%260) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %1046 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1047 = "cute.get_shape"(%1046) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1048:4 = "cute.get_leaves"(%1047) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1049 = "arith.extf"(%1045) : (vector<64xbf16>) -> vector<64xf32>
      %1050 = "arith.mulf"(%1049, %1049) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %1051 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %1052 = "vector.reduction"(%1050, %1051) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %1053 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %1054 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %1055 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %1056 = "nvvm.shfl.sync"(%1053, %1052, %1054, %1055) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1057 = "arith.addf"(%1056, %1052) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1058 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1059 = "nvvm.shfl.sync"(%1053, %1057, %1058, %1055) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1060 = "arith.addf"(%1057, %1059) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1061 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %1062 = "nvvm.shfl.sync"(%1053, %1060, %1061, %1055) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1063 = "arith.addf"(%1060, %1062) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1064 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %1065 = "nvvm.shfl.sync"(%1053, %1063, %1064, %1055) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1066 = "arith.addf"(%1063, %1065) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1067 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %1068 = "nvvm.shfl.sync"(%1053, %1066, %1067, %1055) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1069 = "arith.addf"(%1066, %1068) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1070 = "nvvm.read.ptx.sreg.laneid"() : () -> i32
      %1071 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %1072 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %1073 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %1074 = "nvvm.read.ptx.sreg.ntid.x"() : () -> i32
      %1075 = "nvvm.read.ptx.sreg.ntid.y"() : () -> i32
      %1076 = "arith.muli"(%1072, %1074) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1077 = "arith.addi"(%1071, %1076) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1078 = "arith.muli"(%1073, %1074) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1079 = "arith.muli"(%1078, %1075) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1080 = "arith.addi"(%1077, %1079) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1081 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %1082 = "arith.floordivsi"(%1080, %1081) : (i32, i32) -> i32
      %1083 = "cute.get_layout"(%95) : (!memref_smem_f32_) -> !cute.layout<"(2,2):(1,2)">
      %1084 = "cute.get_shape"(%1083) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %1085:2 = "cute.get_leaves"(%1084) : (!cute.shape<"(2,2)">) -> (!cute.shape<"2">, !cute.shape<"2">)
      %1086 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
      %1087 = "cute.size"(%1086) <{mode = array<i32>}> : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %1088 = "cute.get_leaves"(%1087) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %1089 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %1090 = "arith.floordivsi"(%1082, %1089) : (i32, i32) -> i32
      %1091 = "arith.remsi"(%1082, %1089) : (i32, i32) -> i32
      %1092 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1093 = "arith.cmpi"(%1070, %1092) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %1094 = "scf.if"(%1093) ({
        %1434 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        %1435 = "cute.make_coord"(%1090, %1091) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%95, %1435, %1069) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"(%95) : (!memref_smem_f32_) -> ()
      }, {
        %1433 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        "scf.yield"(%95) : (!memref_smem_f32_) -> ()
      }) : (i1) -> !memref_smem_f32_
      %1095 = "cute.get_iter"(%1094) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %1096 = "cute.get_iter"(%1094) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %1097 = "cute.get_iter"(%1094) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %1098 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%1098) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %1099 = "arith.cmpi"(%1070, %1089) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1100 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %1101 = "scf.if"(%1099) ({
        %1431 = "cute.make_coord"(%1090, %1070) : (i32, i32) -> !cute.coord<"(?,?)">
        %1432 = "cute.memref.load"(%1094, %1431) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%1432) : (f32) -> ()
      }, {
        "scf.yield"(%1100) : (f32) -> ()
      }) : (i1) -> f32
      %1102 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %1103 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %1104 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %1105 = "nvvm.shfl.sync"(%1102, %1101, %1103, %1104) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1106 = "arith.addf"(%1101, %1105) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1107 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1108 = "nvvm.shfl.sync"(%1102, %1106, %1107, %1104) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1109 = "arith.addf"(%1106, %1108) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1110 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %1111 = "nvvm.shfl.sync"(%1102, %1109, %1110, %1104) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1112 = "arith.addf"(%1109, %1111) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1113 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %1114 = "nvvm.shfl.sync"(%1102, %1112, %1113, %1104) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1115 = "arith.addf"(%1112, %1114) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1116 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %1117 = "nvvm.shfl.sync"(%1102, %1115, %1116, %1104) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %1118 = "arith.addf"(%1115, %1117) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1119 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %1120 = "arith.divf"(%1118, %1119) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1121 = "arith.addf"(%1120, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %1122 = "math.rsqrt"(%1121) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      %1123 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%1123) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %1124 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %1125 = "cute.get_shape"(%1124) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1126:4 = "cute.get_leaves"(%1125) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1127 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1128 = "cute.get_shape"(%1127) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1129:4 = "cute.get_leaves"(%1128) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1130 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %1131 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1132 = "cute.right_inverse"(%1131) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %1133 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,8):(1,512)">
      %1134 = "cute.coalesce"(%1133) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %1135 = "cute.get_shape"(%1134) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %1136:2 = "cute.get_leaves"(%1135) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1137 = "cute.get_stride"(%1134) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %1138:2 = "cute.get_leaves"(%1137) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %1139 = "cute.get_shape"(%1134) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %1140:2 = "cute.get_leaves"(%1139) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1141 = "cute.get_shape"(%1134) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %1142:2 = "cute.get_leaves"(%1141) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1143 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1144 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1145 = "cute.size"(%1144) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %1146 = "cute.get_leaves"(%1145) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %1147 = "cute.get_layout"(%221) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %1148 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1149 = "cute.get_iter"(%221) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %1150 = "cute.make_view"(%1149) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1151 = "cute.get_iter"(%1150) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1152 = "cute.get_iter"(%1150) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1153 = "cute.get_iter"(%260) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %1154 = "cute.make_view"(%1153) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1155 = "cute.get_iter"(%1154) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1156 = "cute.get_iter"(%1154) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1157 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1158 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1159 = "cute.get_iter"(%1150) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1160 = "cute.make_view"(%1159) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1161 = "cute.get_iter"(%1160) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1162 = "cute.get_iter"(%1160) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1163 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1164 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1165 = "cute.get_iter"(%1154) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1166 = "cute.make_view"(%1165) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1167 = "cute.get_iter"(%1166) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1168 = "cute.get_iter"(%1166) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1169 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %1170 = "cute.static"() : () -> !cute.layout<"1:0">
      %1171 = "cute.get_iter"(%1160) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1172 = "cute.get_iter"(%1166) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1173 = "cute.get_layout"(%1160) : (!memref_smem_bf16_4) -> !cute.layout<"(8,8):(1,512)">
      %1174 = "cute.get_layout"(%1166) : (!memref_rmem_bf16_3) -> !cute.layout<"(8,8):(1,8)">
      %1175 = "cute.append_to_rank"(%1173, %1170) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,512)">
      %1176 = "cute.append_to_rank"(%1174, %1170) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,8)">
      %1177 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(512))">
      %1178 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(8))">
      %1179 = "cute.size"(%1177) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %1180 = "cute.get_scalars"(%1179) : (!cute.int_tuple<"8">) -> i32
      %1181 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1182 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%1181, %1180, %1182) ({
      ^bb0(%arg11: i32):
        %1415 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %1416 = "cute.get_scalars"(%1415) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1417 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
        %1418 = "cute.crd2idx"(%1415, %1177) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %1419 = "cute.add_offset"(%1171, %1418) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %1420 = "cute.make_view"(%1419, %1417) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %1421 = "cute.get_scalars"(%1415) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
        %1422 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
        %1423 = "cute.crd2idx"(%1415, %1178) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %1424 = "cute.add_offset"(%1172, %1423) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1425 = "cute.make_view"(%1424, %1422) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        %1426 = "cute.get_iter"(%1420) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
        %1427 = "cute.get_iter"(%1425) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<16>>
        %1428 = "builtin.unrealized_conversion_cast"(%1426) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %1429 = "builtin.unrealized_conversion_cast"(%1427) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %1430 = "llvm.load"(%1428) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%1430, %1429) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %1183 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1184 = "cute.get_shape"(%1183) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1185:4 = "cute.get_leaves"(%1184) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1186 = "cute.memref.load_vec"(%260) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %1187 = "cute.get_layout"(%260) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1188 = "cute.get_shape"(%1187) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1189:4 = "cute.get_leaves"(%1188) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1190 = "arith.extf"(%1186) : (vector<64xbf16>) -> vector<64xf32>
      %1191 = "vector.broadcast"(%1122) : (f32) -> vector<64xf32>
      %1192 = "arith.mulf"(%1190, %1191) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %1193 = "cute.get_layout"(%288) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1194 = "cute.get_shape"(%1193) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1195:4 = "cute.get_leaves"(%1194) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1196 = "cute.memref.load_vec"(%288) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %1197 = "cute.get_layout"(%288) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1198 = "cute.get_shape"(%1197) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1199:4 = "cute.get_leaves"(%1198) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1200 = "arith.extf"(%1196) : (vector<64xbf16>) -> vector<64xf32>
      %1201 = "arith.mulf"(%1192, %1200) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %1202 = "arith.truncf"(%1201) : (vector<64xf32>) -> vector<64xbf16>
      %1203 = "cute.get_layout"(%265) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1204 = "cute.get_shape"(%1203) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1205:4 = "cute.get_leaves"(%1204) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1206 = "cute.get_layout"(%265) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1207 = "cute.get_shape"(%1206) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1208:4 = "cute.get_leaves"(%1207) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1209 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %1210 = "cute.size"(%1209) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %1211 = "cute.get_leaves"(%1210) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      %1212 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %1213 = "cute.size"(%1212) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %1214 = "cute.get_leaves"(%1213) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      "cute.memref.store_vec"(%1202, %265) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%596) ({
        %1215 = "cute.get_layout"(%265) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1216 = "cute.get_shape"(%1215) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1217:4 = "cute.get_leaves"(%1216) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1218 = "cute.get_layout"(%238) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1219 = "cute.get_shape"(%1218) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1220:4 = "cute.get_leaves"(%1219) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1221 = "cute.get_layout"(%265) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1222 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1223 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1224 = "cute.append_to_rank"(%1221, %1223) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1225 = "cute.make_view"(%267, %1224) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
        %1226 = "cute.get_iter"(%1225) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %1227 = "cute.get_layout"(%1225) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1228 = "cute.get_shape"(%1227) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1229:4 = "cute.get_leaves"(%1228) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1230 = "cute.get_layout"(%1225) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1231 = "cute.get_shape"(%1230) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1232:4 = "cute.get_leaves"(%1231) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1233 = "cute.get_iter"(%1225) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %1234 = "cute.make_view"(%1233) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
        %1235 = "cute.get_iter"(%1234) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1236 = "cute.get_iter"(%1234) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1237 = "cute.get_layout"(%238) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1238 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1239 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1240 = "cute.append_to_rank"(%1237, %1239) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1241 = "cute.make_view"(%239, %1240) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %1242 = "cute.get_iter"(%1241) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1243 = "cute.get_layout"(%1241) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1244 = "cute.get_shape"(%1243) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1245:4 = "cute.get_leaves"(%1244) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1246 = "cute.get_layout"(%1241) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1247 = "cute.get_shape"(%1246) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1248:4 = "cute.get_leaves"(%1247) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1249 = "cute.get_iter"(%1241) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1250 = "cute.make_view"(%1249) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %1251 = "cute.get_iter"(%1250) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1252 = "cute.get_iter"(%1250) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1253 = "cute.get_layout"(%305) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1254 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1255 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1256 = "cute.append_to_rank"(%1253, %1255) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1257 = "cute.make_view"(%307, %1256) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1258 = "cute.get_iter"(%1257) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1259 = "cute.get_layout"(%1257) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1260 = "cute.get_shape"(%1259) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1261:3 = "cute.get_leaves"(%1260) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1262 = "cute.get_layout"(%1257) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1263 = "cute.get_shape"(%1262) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1264:3 = "cute.get_leaves"(%1263) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1265 = "cute.get_iter"(%1257) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1266 = "cute.make_view"(%1265) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1267 = "cute.get_iter"(%1266) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1268 = "cute.get_iter"(%1266) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1269 = "cute.get_layout"(%1234) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1270 = "cute.get_shape"(%1269) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1271:4 = "cute.get_leaves"(%1270) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1272 = "cute.get_layout"(%1250) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1273 = "cute.get_shape"(%1272) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1274:4 = "cute.get_leaves"(%1273) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1275 = "cute.get_layout"(%1234) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1276 = "cute.size"(%1275) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
        %1277 = "cute.get_leaves"(%1276) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1278 = "cute.get_layout"(%1250) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1279 = "cute.size"(%1278) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1280 = "cute.get_leaves"(%1279) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1281 = "cute.static"() : () -> !cute.layout<"1:0">
        %1282 = "cute.get_iter"(%1234) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1283 = "cute.get_iter"(%1250) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1284 = "cute.get_layout"(%1234) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1285 = "cute.get_layout"(%1250) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1286 = "cute.append_to_rank"(%1284, %1281) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1287 = "cute.append_to_rank"(%1285, %1281) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1288 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
        %1289 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1290 = "cute.get_iter"(%1266) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1291 = "cute.get_layout"(%1266) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1292 = "cute.append_to_rank"(%1291, %1281) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1293 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %1294 = "cute.size"(%1288) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"1">
        %1295 = "cute.get_scalars"(%1294) : (!cute.int_tuple<"1">) -> i32
        %1296 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1297 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1296, %1295, %1297) ({
        ^bb0(%arg10: i32):
          %1298 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
          %1299 = "cute.get_scalars"(%1298) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1300 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,8))">
          %1301 = "cute.crd2idx"(%1298, %1288) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
          %1302 = "cute.add_offset"(%1282, %1301) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %1303 = "cute.make_view"(%1302, %1300) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
          %1304 = "cute.get_scalars"(%1298) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1305 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8)):((1,512))">
          %1306 = "cute.crd2idx"(%1298, %1289) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1307 = "cute.add_offset"(%1283, %1306) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %1308 = "cute.make_view"(%1307, %1305) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %1309 = "cute.get_scalars"(%1298) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %1310 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
          %1311 = "cute.crd2idx"(%1298, %1293) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %1312 = "cute.add_offset"(%1290, %1311) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1313 = "cute.make_view"(%1312, %1310) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          %1314 = "cute.get_iter"(%1303) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
          %1315 = "cute.get_iter"(%1308) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
          %1316 = "cute.get_iter"(%1313) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
          %1317 = "builtin.unrealized_conversion_cast"(%1316) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1318 = "llvm.load"(%1317) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1319 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1320 = "llvm.icmp"(%1318, %1319) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1320) ({
            %1412 = "builtin.unrealized_conversion_cast"(%1314) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %1413 = "builtin.unrealized_conversion_cast"(%1315) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1414 = "llvm.load"(%1412) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1414, %1413) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1321 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %1322 = "cute.add_offset"(%1316, %1321) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %1323 = "builtin.unrealized_conversion_cast"(%1322) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1324 = "llvm.load"(%1323) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1325 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1326 = "llvm.icmp"(%1324, %1325) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1326) ({
            %1405 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"8">
            %1406 = "cute.add_offset"(%1314, %1405) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %1407 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"512">
            %1408 = "cute.add_offset"(%1315, %1407) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %1409 = "builtin.unrealized_conversion_cast"(%1406) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1410 = "builtin.unrealized_conversion_cast"(%1408) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1411 = "llvm.load"(%1409) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1411, %1410) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1327 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %1328 = "cute.add_offset"(%1316, %1327) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %1329 = "builtin.unrealized_conversion_cast"(%1328) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1330 = "llvm.load"(%1329) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1331 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1332 = "llvm.icmp"(%1330, %1331) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1332) ({
            %1398 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
            %1399 = "cute.add_offset"(%1314, %1398) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %1400 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1024">
            %1401 = "cute.add_offset"(%1315, %1400) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %1402 = "builtin.unrealized_conversion_cast"(%1399) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %1403 = "builtin.unrealized_conversion_cast"(%1401) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1404 = "llvm.load"(%1402) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1404, %1403) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1333 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %1334 = "cute.add_offset"(%1316, %1333) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %1335 = "builtin.unrealized_conversion_cast"(%1334) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1336 = "llvm.load"(%1335) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1337 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1338 = "llvm.icmp"(%1336, %1337) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1338) ({
            %1391 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"24">
            %1392 = "cute.add_offset"(%1314, %1391) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %1393 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1536">
            %1394 = "cute.add_offset"(%1315, %1393) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %1395 = "builtin.unrealized_conversion_cast"(%1392) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1396 = "builtin.unrealized_conversion_cast"(%1394) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1397 = "llvm.load"(%1395) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1397, %1396) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1339 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
          %1340 = "cute.add_offset"(%1316, %1339) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %1341 = "builtin.unrealized_conversion_cast"(%1340) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1342 = "llvm.load"(%1341) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1343 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1344 = "llvm.icmp"(%1342, %1343) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1344) ({
            %1384 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
            %1385 = "cute.add_offset"(%1314, %1384) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %1386 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2048">
            %1387 = "cute.add_offset"(%1315, %1386) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %1388 = "builtin.unrealized_conversion_cast"(%1385) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %1389 = "builtin.unrealized_conversion_cast"(%1387) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1390 = "llvm.load"(%1388) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1390, %1389) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1345 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
          %1346 = "cute.add_offset"(%1316, %1345) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %1347 = "builtin.unrealized_conversion_cast"(%1346) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1348 = "llvm.load"(%1347) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1349 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1350 = "llvm.icmp"(%1348, %1349) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1350) ({
            %1377 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"40">
            %1378 = "cute.add_offset"(%1314, %1377) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %1379 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2560">
            %1380 = "cute.add_offset"(%1315, %1379) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %1381 = "builtin.unrealized_conversion_cast"(%1378) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1382 = "builtin.unrealized_conversion_cast"(%1380) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1383 = "llvm.load"(%1381) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1383, %1382) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1351 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
          %1352 = "cute.add_offset"(%1316, %1351) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %1353 = "builtin.unrealized_conversion_cast"(%1352) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1354 = "llvm.load"(%1353) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1355 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1356 = "llvm.icmp"(%1354, %1355) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1356) ({
            %1370 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"48">
            %1371 = "cute.add_offset"(%1314, %1370) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %1372 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3072">
            %1373 = "cute.add_offset"(%1315, %1372) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %1374 = "builtin.unrealized_conversion_cast"(%1371) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %1375 = "builtin.unrealized_conversion_cast"(%1373) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1376 = "llvm.load"(%1374) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1376, %1375) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %1357 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
          %1358 = "cute.add_offset"(%1316, %1357) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %1359 = "builtin.unrealized_conversion_cast"(%1358) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1360 = "llvm.load"(%1359) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1361 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1362 = "llvm.icmp"(%1360, %1361) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1362) ({
            %1363 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"56">
            %1364 = "cute.add_offset"(%1314, %1363) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %1365 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3584">
            %1366 = "cute.add_offset"(%1315, %1365) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %1367 = "builtin.unrealized_conversion_cast"(%1364) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1368 = "builtin.unrealized_conversion_cast"(%1366) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1369 = "llvm.load"(%1367) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1369, %1368) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!cute.ptr<bf16, gmem, align<16>>, !cute.ptr<bf16, gmem, align<16>>, !cute.ptr<bf16, gmem, align<16>>, i32, f32, !cuda.stream) -> i32, sym_name = "cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0"}> ({
  ^bb0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream):
    %0 = "cute.make_shape"(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %1 = "cute.make_stride"() : () -> !cute.stride<"(4096,1)">
    %2 = "cute.make_layout"(%0, %1) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %3 = "cute.make_view"(%arg0, %2) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %4 = "cute.get_iter"(%3) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
    %5 = "cute.make_shape"(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %6 = "cute.make_stride"() : () -> !cute.stride<"(4096,1)">
    %7 = "cute.make_layout"(%5, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %8 = "cute.make_view"(%arg2, %7) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %9 = "cute.get_iter"(%8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
    %10 = "cute.make_shape"() : () -> !cute.shape<"(4096)">
    %11 = "cute.make_stride"() : () -> !cute.stride<"(1)">
    %12 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4096):(1)">
    %13 = "cute.make_view"(%arg1, %12) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(4096):(1)">) -> !memref_gmem_bf16_1
    %14 = "cute.get_iter"(%13) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
    %15 = "cute.make_shape"() : () -> !cute.shape<"((64,2),(8,8))">
    %16 = "cute.make_stride"() : () -> !cute.stride<"((16,1),(2,1024))">
    %17 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
    %18 = "cute.make_int_tuple"(%arg3) : (i32) -> !cute.int_tuple<"?">
    %19 = "cute.make_tile"() : () -> !cute.tile<"2:1">
    %20 = "cute.get_scalars"(%18) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
    %21 = "arith.constant"() <{value = 2 : i32}> : () -> i32
    %22 = "arith.ceildivsi"(%20, %21) : (i32, i32) -> i32
    %23 = "cute.make_int_tuple"(%22) : (i32) -> !cute.int_tuple<"?">
    %24 = "cute.get_leaves"(%23) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %25 = "cute.get_scalars"(%24) : (!cute.int_tuple<"?">) -> i32
    %26 = "cute.get_layout"(%3) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
    %27 = "cute.get_layout"(%13) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
    %28 = "cute.get_layout"(%8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
    %29 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
    %30 = "arith.extsi"(%29) : (i32) -> i64
    %31 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %32 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %33 = "cuda.launch_cfg.create"(%31, %32, %32, %30, %25, %32, %32, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %34 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%33, %34) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %35 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%33, %35) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %36 = "cuda.launch_ex"(%33, %3, %13, %8, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %37 = "cuda.cast"(%36) : (!cuda.result) -> i32
    "cuda.return_if_error"(%37) : (i32) -> ()
    %38 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%38) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
