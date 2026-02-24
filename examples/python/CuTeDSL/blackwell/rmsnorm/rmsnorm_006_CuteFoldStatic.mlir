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
      %27 = "cute.static"() : () -> !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
      %28 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %29 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %30 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %31 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %32 = "cute.get_shape"(%31) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %33 = "cute.static"() : () -> !cute.shape<"4096">
      %34:2 = "cute.get_leaves"(%32) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %35 = "cute.to_int_tuple"(%34#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %36 = "cute.get_scalars"(%35) : (!cute.int_tuple<"?">) -> i32
      %37 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %38 = "cute.static"() : () -> !cute.layout<"(2,4096):(4096,1)">
      %39 = "cute.static"() : () -> !cute.int_tuple<"16384">
      %40 = "cute.add_offset"(%37, %39) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %41 = "cute.recast_iter"(%37) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %42 = "cute.make_view"(%41, %38) : (!cute.ptr<bf16, smem, align<1024>>, !cute.layout<"(2,4096):(4096,1)">) -> !memref_smem_bf16_
      %43 = "cute.static"() : () -> !cute.layout<"(2,2):(1,2)">
      %44 = "cute.recast_iter"(%40) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %45 = "cute.make_view"(%44, %43) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %46 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %47 = "cute.get_shape"(%46) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %48 = "cute.static"() : () -> !cute.shape<"4096">
      %49:2 = "cute.get_leaves"(%47) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %50 = "cute.to_int_tuple"(%49#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %51 = "cute.make_shape"(%50) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %52 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %53 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %54 = "cute.make_layout"(%51, %53) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %55 = "cute.make_view"(%52, %54) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,4096):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %56 = "cute.make_coord"(%30) : (i32) -> !cute.coord<"(?,0)">
      %57 = "cute.get_scalars"(%56) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %58 = "cute.make_coord"(%57) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %59 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %60 = "cute.get_scalars"(%59) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %61 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %62 = "arith.ceildivsi"(%60, %61) : (i32, i32) -> i32
      %63 = "cute.make_shape"(%62) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %64 = "cute.static"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %65 = "cute.make_layout"(%63, %64) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %66 = "cute.crd2idx"(%58, %65) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %67 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %68 = "cute.add_offset"(%67, %66) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %69 = "cute.make_view"(%68) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %70 = "cute.make_coord"(%30) : (i32) -> !cute.coord<"(?,0)">
      %71 = "cute.get_scalars"(%70) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %72 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %73 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %74 = "cute.get_scalars"(%73) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %75 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %76 = "arith.ceildivsi"(%74, %75) : (i32, i32) -> i32
      %77 = "cute.make_shape"(%76) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %78 = "cute.static"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %79 = "cute.make_layout"(%77, %78) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %80 = "cute.crd2idx"(%72, %79) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %81 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %82 = "cute.add_offset"(%81, %80) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %83 = "cute.make_view"(%82) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %84 = "cute.make_coord"(%30) : (i32) -> !cute.coord<"(?,0)">
      %85 = "cute.get_scalars"(%84) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %86 = "cute.make_coord"(%85) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %87 = "cute.get_layout"(%55) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %88 = "cute.get_scalars"(%87) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %89 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %90 = "arith.ceildivsi"(%88, %89) : (i32, i32) -> i32
      %91 = "cute.make_shape"(%90) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %92 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %93 = "cute.make_layout"(%91, %92) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %94 = "cute.crd2idx"(%86, %93) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %95 = "cute.get_iter"(%55) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %96 = "cute.add_offset"(%95, %94) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %97 = "cute.make_view"(%96) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %98 = "cute.static"() : () -> !cute.layout<"((2),4096):((0),1)">
      %99 = "cute.make_view"(%28, %98) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((2),4096):((0),1)">) -> !memref_gmem_bf16_3
      %100 = "cute.static"() : () -> !cute.int_tuple<"0">
      %101 = "cute.get_iter"(%99) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %102 = "cute.add_offset"(%101, %100) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %103 = "cute.make_view"(%102) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_4
      %104 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %105 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %106 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %107 = "cute.make_tiled_copy"(%104) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %108 = "cute.make_tiled_copy"(%105) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %109 = "cute.make_tiled_copy"(%106) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %110 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %111 = "cute.get_iter"(%69) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %112 = "cute.get_scalars"(%110) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %113 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %114 = "arith.divsi"(%112, %113) : (i32, i32) -> i32
      %115 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %116 = "arith.remsi"(%112, %115) : (i32, i32) -> i32
      %117 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %118 = "arith.muli"(%116, %117) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %119 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %120 = "arith.muli"(%114, %119) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %121 = "arith.addi"(%118, %120) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %122 = "cute.assume"(%121) : (i32) -> !cute.i32<divby 8>
      %123 = "cute.make_int_tuple"(%122) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %124 = "cute.add_offset"(%111, %123) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %125 = "cute.make_view"(%124) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %126 = "cute.get_iter"(%125) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %127 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %128 = "cute.get_iter"(%42) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %129 = "cute.get_scalars"(%127) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %130 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %131 = "arith.divsi"(%129, %130) : (i32, i32) -> i32
      %132 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %133 = "arith.remsi"(%129, %132) : (i32, i32) -> i32
      %134 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %135 = "arith.muli"(%133, %134) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %136 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %137 = "arith.muli"(%131, %136) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %138 = "arith.addi"(%135, %137) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %139 = "cute.assume"(%138) : (i32) -> !cute.i32<divby 8>
      %140 = "cute.make_int_tuple"(%139) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %141 = "cute.add_offset"(%128, %140) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %142 = "cute.make_view"(%141) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_1
      %143 = "cute.get_iter"(%142) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %144 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %145 = "cute.get_iter"(%83) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %146 = "cute.get_scalars"(%144) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %147 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %148 = "arith.divsi"(%146, %147) : (i32, i32) -> i32
      %149 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %150 = "arith.remsi"(%146, %149) : (i32, i32) -> i32
      %151 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %152 = "arith.muli"(%150, %151) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %153 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %154 = "arith.muli"(%148, %153) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %155 = "arith.addi"(%152, %154) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %156 = "cute.assume"(%155) : (i32) -> !cute.i32<divby 8>
      %157 = "cute.make_int_tuple"(%156) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %158 = "cute.add_offset"(%145, %157) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %159 = "cute.make_view"(%158) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %160 = "cute.get_iter"(%159) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %161 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %162 = "cute.get_iter"(%97) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %163 = "cute.get_scalars"(%161) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %164 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %165 = "arith.divsi"(%163, %164) : (i32, i32) -> i32
      %166 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %167 = "arith.remsi"(%163, %166) : (i32, i32) -> i32
      %168 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %169 = "arith.muli"(%167, %168) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %170 = "cute.assume"(%169) : (i32) -> !cute.i32<divby 8>
      %171 = "cute.make_int_tuple"(%165, %170) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %172 = "cute.add_offset"(%162, %171) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %173 = "cute.make_view"(%172) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %174 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %175 = "cute.memref.alloca"(%174) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %176 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %177 = "cute.memref.alloca"(%176) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %178 = "cute.get_iter"(%177) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %179 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %180 = "cute.get_iter"(%103) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %181 = "cute.get_scalars"(%179) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %182 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %183 = "arith.remsi"(%181, %182) : (i32, i32) -> i32
      %184 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %185 = "arith.muli"(%183, %184) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %186 = "cute.assume"(%185) : (i32) -> !cute.i32<divby 8>
      %187 = "cute.make_int_tuple"(%186) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %188 = "cute.add_offset"(%180, %187) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %189 = "cute.make_view"(%188) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_5
      %190 = "cute.get_iter"(%189) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %191 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %192 = "cute.memref.alloca"(%191) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %193 = "cute.get_iter"(%192) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %194 = "cute.get_iter"(%192) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %195 = "cute.make_view"(%194) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_
      %196 = "cute.static"() : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %197 = "cute.memref.alloca"(%196) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %198 = "cute.get_iter"(%197) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %199 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %200 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %201 = "cute.add_offset"(%200, %199) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %202 = "cute.make_view"(%201) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %203 = "cute.get_iter"(%202) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %204 = "cute.deref_arith_tuple_iter"(%203) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %205:2 = "cute.get_leaves"(%204) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %206 = "cute.make_coord"(%205#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %207 = "cute.static"() : () -> !cute.coord<"4096">
      %208 = "cute.get_scalars"(%206) : (!cute.coord<"?{div=8}">) -> i32
      %209 = "cute.get_scalars"(%207) : (!cute.coord<"4096">) -> i32
      %210 = "arith.constant"() <{value = true}> : () -> i1
      %211 = "arith.cmpi"(%208, %209) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %212 = "arith.andi"(%210, %211) : (i1, i1) -> i1
      %213 = "arith.extui"(%212) : (i1) -> i8
      %214 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%197, %214, %213) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %215 = "cute.static"() : () -> !cute.int_tuple<"(0,512)">
      %216 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %217 = "cute.add_offset"(%216, %215) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %218 = "cute.make_view"(%217) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %219 = "cute.get_iter"(%218) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %220 = "cute.deref_arith_tuple_iter"(%219) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %221:2 = "cute.get_leaves"(%220) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %222 = "cute.make_coord"(%221#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %223 = "cute.static"() : () -> !cute.coord<"4096">
      %224 = "cute.get_scalars"(%222) : (!cute.coord<"?{div=8}">) -> i32
      %225 = "cute.get_scalars"(%223) : (!cute.coord<"4096">) -> i32
      %226 = "arith.constant"() <{value = true}> : () -> i1
      %227 = "arith.cmpi"(%224, %225) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %228 = "arith.andi"(%226, %227) : (i1, i1) -> i1
      %229 = "arith.extui"(%228) : (i1) -> i8
      %230 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%197, %230, %229) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %231 = "cute.static"() : () -> !cute.int_tuple<"(0,1024)">
      %232 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %233 = "cute.add_offset"(%232, %231) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %234 = "cute.make_view"(%233) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %235 = "cute.get_iter"(%234) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %236 = "cute.deref_arith_tuple_iter"(%235) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %237:2 = "cute.get_leaves"(%236) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %238 = "cute.make_coord"(%237#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %239 = "cute.static"() : () -> !cute.coord<"4096">
      %240 = "cute.get_scalars"(%238) : (!cute.coord<"?{div=8}">) -> i32
      %241 = "cute.get_scalars"(%239) : (!cute.coord<"4096">) -> i32
      %242 = "arith.constant"() <{value = true}> : () -> i1
      %243 = "arith.cmpi"(%240, %241) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %244 = "arith.andi"(%242, %243) : (i1, i1) -> i1
      %245 = "arith.extui"(%244) : (i1) -> i8
      %246 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%197, %246, %245) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %247 = "cute.static"() : () -> !cute.int_tuple<"(0,1536)">
      %248 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %249 = "cute.add_offset"(%248, %247) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %250 = "cute.make_view"(%249) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %251 = "cute.get_iter"(%250) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %252 = "cute.deref_arith_tuple_iter"(%251) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %253:2 = "cute.get_leaves"(%252) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %254 = "cute.make_coord"(%253#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %255 = "cute.static"() : () -> !cute.coord<"4096">
      %256 = "cute.get_scalars"(%254) : (!cute.coord<"?{div=8}">) -> i32
      %257 = "cute.get_scalars"(%255) : (!cute.coord<"4096">) -> i32
      %258 = "arith.constant"() <{value = true}> : () -> i1
      %259 = "arith.cmpi"(%256, %257) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %260 = "arith.andi"(%258, %259) : (i1, i1) -> i1
      %261 = "arith.extui"(%260) : (i1) -> i8
      %262 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%197, %262, %261) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %263 = "cute.static"() : () -> !cute.int_tuple<"(0,2048)">
      %264 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %265 = "cute.add_offset"(%264, %263) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %266 = "cute.make_view"(%265) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %267 = "cute.get_iter"(%266) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %268 = "cute.deref_arith_tuple_iter"(%267) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %269:2 = "cute.get_leaves"(%268) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %270 = "cute.make_coord"(%269#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %271 = "cute.static"() : () -> !cute.coord<"4096">
      %272 = "cute.get_scalars"(%270) : (!cute.coord<"?{div=8}">) -> i32
      %273 = "cute.get_scalars"(%271) : (!cute.coord<"4096">) -> i32
      %274 = "arith.constant"() <{value = true}> : () -> i1
      %275 = "arith.cmpi"(%272, %273) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %276 = "arith.andi"(%274, %275) : (i1, i1) -> i1
      %277 = "arith.extui"(%276) : (i1) -> i8
      %278 = "cute.static"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%197, %278, %277) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %279 = "cute.static"() : () -> !cute.int_tuple<"(0,2560)">
      %280 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %281 = "cute.add_offset"(%280, %279) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %282 = "cute.make_view"(%281) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %283 = "cute.get_iter"(%282) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %284 = "cute.deref_arith_tuple_iter"(%283) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %285:2 = "cute.get_leaves"(%284) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %286 = "cute.make_coord"(%285#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %287 = "cute.static"() : () -> !cute.coord<"4096">
      %288 = "cute.get_scalars"(%286) : (!cute.coord<"?{div=8}">) -> i32
      %289 = "cute.get_scalars"(%287) : (!cute.coord<"4096">) -> i32
      %290 = "arith.constant"() <{value = true}> : () -> i1
      %291 = "arith.cmpi"(%288, %289) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %292 = "arith.andi"(%290, %291) : (i1, i1) -> i1
      %293 = "arith.extui"(%292) : (i1) -> i8
      %294 = "cute.static"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%197, %294, %293) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %295 = "cute.static"() : () -> !cute.int_tuple<"(0,3072)">
      %296 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %297 = "cute.add_offset"(%296, %295) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %298 = "cute.make_view"(%297) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %299 = "cute.get_iter"(%298) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %300 = "cute.deref_arith_tuple_iter"(%299) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %301:2 = "cute.get_leaves"(%300) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %302 = "cute.make_coord"(%301#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %303 = "cute.static"() : () -> !cute.coord<"4096">
      %304 = "cute.get_scalars"(%302) : (!cute.coord<"?{div=8}">) -> i32
      %305 = "cute.get_scalars"(%303) : (!cute.coord<"4096">) -> i32
      %306 = "arith.constant"() <{value = true}> : () -> i1
      %307 = "arith.cmpi"(%304, %305) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %308 = "arith.andi"(%306, %307) : (i1, i1) -> i1
      %309 = "arith.extui"(%308) : (i1) -> i8
      %310 = "cute.static"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%197, %310, %309) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %311 = "cute.static"() : () -> !cute.int_tuple<"(0,3584)">
      %312 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %313 = "cute.add_offset"(%312, %311) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %314 = "cute.make_view"(%313) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %315 = "cute.get_iter"(%314) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %316 = "cute.deref_arith_tuple_iter"(%315) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %317:2 = "cute.get_leaves"(%316) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %318 = "cute.make_coord"(%317#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %319 = "cute.static"() : () -> !cute.coord<"4096">
      %320 = "cute.get_scalars"(%318) : (!cute.coord<"?{div=8}">) -> i32
      %321 = "cute.get_scalars"(%319) : (!cute.coord<"4096">) -> i32
      %322 = "arith.constant"() <{value = true}> : () -> i1
      %323 = "arith.cmpi"(%320, %321) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %324 = "arith.andi"(%322, %323) : (i1, i1) -> i1
      %325 = "arith.extui"(%324) : (i1) -> i8
      %326 = "cute.static"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%197, %326, %325) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %327 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %328 = "cute.get_iter"(%173) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %329 = "cute.add_offset"(%328, %327) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %330 = "cute.make_view"(%329) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %331 = "cute.get_iter"(%330) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %332 = "cute.deref_arith_tuple_iter"(%331) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %333:2 = "cute.get_leaves"(%332) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %334 = "cute.get_scalars"(%333#0) : (!cute.int_tuple<"?">) -> i32
      %335 = "arith.cmpi"(%334, %36) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%335) ({
        %890 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %891 = "cute.make_view"(%126, %890) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %892 = "cute.get_iter"(%891) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %893 = "cute.make_view"(%892) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %894 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %895 = "cute.make_view"(%143, %894) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_smem_bf16_1
        %896 = "cute.get_iter"(%895) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %897 = "cute.make_view"(%896) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_2
        %898 = "cute.static"() : () -> !cute.layout<"(8,1,1):(1,0,1)">
        %899 = "cute.make_view"(%198, %898) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %900 = "cute.get_iter"(%899) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %901 = "cute.make_view"(%900) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %902 = "cute.static"() : () -> !cute.layout<"1:0">
        %903 = "cute.get_iter"(%893) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %904 = "cute.get_iter"(%897) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %905 = "cute.get_iter"(%901) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %906 = "cute.static"() : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %907 = "cute.static"() : () -> !cute.int_tuple<"1">
        %908 = "cute.get_scalars"(%907) : (!cute.int_tuple<"1">) -> i32
        %909 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %910 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%909, %908, %910) ({
        ^bb0(%arg14: i32):
          %911 = "cute.make_coord"(%arg14) : (i32) -> !cute.coord<"(_,?)">
          %912 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,512))">
          %913 = "cute.static"() : () -> !cute.int_tuple<"0">
          %914 = "cute.add_offset"(%903, %913) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %915 = "cute.make_view"(%914, %912) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %916 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,512))">
          %917 = "cute.static"() : () -> !cute.int_tuple<"0">
          %918 = "cute.add_offset"(%904, %917) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %919 = "cute.make_view"(%918, %916) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_smem_bf16_3
          %920 = "cute.static"() : () -> !cute.layout<"(8):(1)">
          %921 = "cute.crd2idx"(%911, %906) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %922 = "cute.add_offset"(%905, %921) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %923 = "cute.make_view"(%922, %920) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          %924 = "cute.get_iter"(%915) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
          %925 = "cute.get_iter"(%919) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %926 = "cute.get_iter"(%923) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
          %927 = "builtin.unrealized_conversion_cast"(%926) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %928 = "llvm.load"(%927) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %929 = "llvm.trunc"(%928) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %930 = "cute.recast_iter"(%924) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %931 = "cute.recast_iter"(%925) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%931, %930, %929) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %932 = "cute.static"() : () -> !cute.int_tuple<"512">
          %933 = "cute.add_offset"(%924, %932) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %934 = "cute.static"() : () -> !cute.int_tuple<"512">
          %935 = "cute.add_offset"(%925, %934) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
          %936 = "cute.static"() : () -> !cute.int_tuple<"1">
          %937 = "cute.add_offset"(%926, %936) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %938 = "builtin.unrealized_conversion_cast"(%937) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %939 = "llvm.load"(%938) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %940 = "llvm.trunc"(%939) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %941 = "cute.recast_iter"(%933) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %942 = "cute.recast_iter"(%935) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%942, %941, %940) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %943 = "cute.static"() : () -> !cute.int_tuple<"1024">
          %944 = "cute.add_offset"(%924, %943) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %945 = "cute.static"() : () -> !cute.int_tuple<"1024">
          %946 = "cute.add_offset"(%925, %945) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %947 = "cute.static"() : () -> !cute.int_tuple<"2">
          %948 = "cute.add_offset"(%926, %947) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %949 = "builtin.unrealized_conversion_cast"(%948) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %950 = "llvm.load"(%949) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %951 = "llvm.trunc"(%950) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %952 = "cute.recast_iter"(%944) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %953 = "cute.recast_iter"(%946) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%953, %952, %951) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %954 = "cute.static"() : () -> !cute.int_tuple<"1536">
          %955 = "cute.add_offset"(%924, %954) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %956 = "cute.static"() : () -> !cute.int_tuple<"1536">
          %957 = "cute.add_offset"(%925, %956) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
          %958 = "cute.static"() : () -> !cute.int_tuple<"3">
          %959 = "cute.add_offset"(%926, %958) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %960 = "builtin.unrealized_conversion_cast"(%959) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %961 = "llvm.load"(%960) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %962 = "llvm.trunc"(%961) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %963 = "cute.recast_iter"(%955) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %964 = "cute.recast_iter"(%957) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%964, %963, %962) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %965 = "cute.static"() : () -> !cute.int_tuple<"2048">
          %966 = "cute.add_offset"(%924, %965) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %967 = "cute.static"() : () -> !cute.int_tuple<"2048">
          %968 = "cute.add_offset"(%925, %967) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %969 = "cute.static"() : () -> !cute.int_tuple<"4">
          %970 = "cute.add_offset"(%926, %969) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %971 = "builtin.unrealized_conversion_cast"(%970) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %972 = "llvm.load"(%971) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %973 = "llvm.trunc"(%972) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %974 = "cute.recast_iter"(%966) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %975 = "cute.recast_iter"(%968) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%975, %974, %973) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %976 = "cute.static"() : () -> !cute.int_tuple<"2560">
          %977 = "cute.add_offset"(%924, %976) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %978 = "cute.static"() : () -> !cute.int_tuple<"2560">
          %979 = "cute.add_offset"(%925, %978) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
          %980 = "cute.static"() : () -> !cute.int_tuple<"5">
          %981 = "cute.add_offset"(%926, %980) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %982 = "builtin.unrealized_conversion_cast"(%981) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %983 = "llvm.load"(%982) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %984 = "llvm.trunc"(%983) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %985 = "cute.recast_iter"(%977) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %986 = "cute.recast_iter"(%979) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%986, %985, %984) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %987 = "cute.static"() : () -> !cute.int_tuple<"3072">
          %988 = "cute.add_offset"(%924, %987) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %989 = "cute.static"() : () -> !cute.int_tuple<"3072">
          %990 = "cute.add_offset"(%925, %989) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %991 = "cute.static"() : () -> !cute.int_tuple<"6">
          %992 = "cute.add_offset"(%926, %991) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %993 = "builtin.unrealized_conversion_cast"(%992) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %994 = "llvm.load"(%993) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %995 = "llvm.trunc"(%994) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %996 = "cute.recast_iter"(%988) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %997 = "cute.recast_iter"(%990) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%997, %996, %995) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          %998 = "cute.static"() : () -> !cute.int_tuple<"3584">
          %999 = "cute.add_offset"(%924, %998) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %1000 = "cute.static"() : () -> !cute.int_tuple<"3584">
          %1001 = "cute.add_offset"(%925, %1000) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
          %1002 = "cute.static"() : () -> !cute.int_tuple<"7">
          %1003 = "cute.add_offset"(%926, %1002) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %1004 = "builtin.unrealized_conversion_cast"(%1003) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1005 = "llvm.load"(%1004) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1006 = "llvm.trunc"(%1005) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %1007 = "cute.recast_iter"(%999) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %1008 = "cute.recast_iter"(%1001) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%1008, %1007, %1006) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %336 = "cute.make_coord"(%29) : (i32) -> !cute.coord<"?">
      %337 = "cute.get_iter"(%97) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %338 = "cute.get_scalars"(%336) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %339 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %340 = "arith.divsi"(%338, %339) : (i32, i32) -> i32
      %341 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %342 = "arith.remsi"(%338, %341) : (i32, i32) -> i32
      %343 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %344 = "arith.muli"(%342, %343) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %345 = "cute.assume"(%344) : (i32) -> !cute.i32<divby 8>
      %346 = "cute.make_int_tuple"(%340, %345) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %347 = "cute.add_offset"(%337, %346) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %348 = "cute.make_view"(%347) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %349 = "cute.static"() : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %350 = "cute.memref.alloca"(%349) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %351 = "cute.get_iter"(%350) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %352 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %353 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %354 = "cute.add_offset"(%353, %352) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %355 = "cute.make_view"(%354) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %356 = "cute.get_iter"(%355) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %357 = "cute.deref_arith_tuple_iter"(%356) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %358:2 = "cute.get_leaves"(%357) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %359 = "cute.make_coord"(%358#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %360 = "cute.static"() : () -> !cute.coord<"4096">
      %361 = "cute.get_scalars"(%359) : (!cute.coord<"?{div=8}">) -> i32
      %362 = "cute.get_scalars"(%360) : (!cute.coord<"4096">) -> i32
      %363 = "arith.constant"() <{value = true}> : () -> i1
      %364 = "arith.cmpi"(%361, %362) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %365 = "arith.andi"(%363, %364) : (i1, i1) -> i1
      %366 = "arith.extui"(%365) : (i1) -> i8
      %367 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%350, %367, %366) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %368 = "cute.static"() : () -> !cute.int_tuple<"(0,512)">
      %369 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %370 = "cute.add_offset"(%369, %368) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %371 = "cute.make_view"(%370) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %372 = "cute.get_iter"(%371) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %373 = "cute.deref_arith_tuple_iter"(%372) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %374:2 = "cute.get_leaves"(%373) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %375 = "cute.make_coord"(%374#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %376 = "cute.static"() : () -> !cute.coord<"4096">
      %377 = "cute.get_scalars"(%375) : (!cute.coord<"?{div=8}">) -> i32
      %378 = "cute.get_scalars"(%376) : (!cute.coord<"4096">) -> i32
      %379 = "arith.constant"() <{value = true}> : () -> i1
      %380 = "arith.cmpi"(%377, %378) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %381 = "arith.andi"(%379, %380) : (i1, i1) -> i1
      %382 = "arith.extui"(%381) : (i1) -> i8
      %383 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%350, %383, %382) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %384 = "cute.static"() : () -> !cute.int_tuple<"(0,1024)">
      %385 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %386 = "cute.add_offset"(%385, %384) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %387 = "cute.make_view"(%386) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %388 = "cute.get_iter"(%387) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %389 = "cute.deref_arith_tuple_iter"(%388) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %390:2 = "cute.get_leaves"(%389) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %391 = "cute.make_coord"(%390#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %392 = "cute.static"() : () -> !cute.coord<"4096">
      %393 = "cute.get_scalars"(%391) : (!cute.coord<"?{div=8}">) -> i32
      %394 = "cute.get_scalars"(%392) : (!cute.coord<"4096">) -> i32
      %395 = "arith.constant"() <{value = true}> : () -> i1
      %396 = "arith.cmpi"(%393, %394) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %397 = "arith.andi"(%395, %396) : (i1, i1) -> i1
      %398 = "arith.extui"(%397) : (i1) -> i8
      %399 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%350, %399, %398) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %400 = "cute.static"() : () -> !cute.int_tuple<"(0,1536)">
      %401 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %402 = "cute.add_offset"(%401, %400) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %403 = "cute.make_view"(%402) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %404 = "cute.get_iter"(%403) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %405 = "cute.deref_arith_tuple_iter"(%404) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %406:2 = "cute.get_leaves"(%405) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %407 = "cute.make_coord"(%406#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %408 = "cute.static"() : () -> !cute.coord<"4096">
      %409 = "cute.get_scalars"(%407) : (!cute.coord<"?{div=8}">) -> i32
      %410 = "cute.get_scalars"(%408) : (!cute.coord<"4096">) -> i32
      %411 = "arith.constant"() <{value = true}> : () -> i1
      %412 = "arith.cmpi"(%409, %410) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %413 = "arith.andi"(%411, %412) : (i1, i1) -> i1
      %414 = "arith.extui"(%413) : (i1) -> i8
      %415 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%350, %415, %414) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %416 = "cute.static"() : () -> !cute.int_tuple<"(0,2048)">
      %417 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %418 = "cute.add_offset"(%417, %416) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %419 = "cute.make_view"(%418) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %420 = "cute.get_iter"(%419) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %421 = "cute.deref_arith_tuple_iter"(%420) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %422:2 = "cute.get_leaves"(%421) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %423 = "cute.make_coord"(%422#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %424 = "cute.static"() : () -> !cute.coord<"4096">
      %425 = "cute.get_scalars"(%423) : (!cute.coord<"?{div=8}">) -> i32
      %426 = "cute.get_scalars"(%424) : (!cute.coord<"4096">) -> i32
      %427 = "arith.constant"() <{value = true}> : () -> i1
      %428 = "arith.cmpi"(%425, %426) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %429 = "arith.andi"(%427, %428) : (i1, i1) -> i1
      %430 = "arith.extui"(%429) : (i1) -> i8
      %431 = "cute.static"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%350, %431, %430) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %432 = "cute.static"() : () -> !cute.int_tuple<"(0,2560)">
      %433 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %434 = "cute.add_offset"(%433, %432) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %435 = "cute.make_view"(%434) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %436 = "cute.get_iter"(%435) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %437 = "cute.deref_arith_tuple_iter"(%436) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %438:2 = "cute.get_leaves"(%437) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %439 = "cute.make_coord"(%438#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %440 = "cute.static"() : () -> !cute.coord<"4096">
      %441 = "cute.get_scalars"(%439) : (!cute.coord<"?{div=8}">) -> i32
      %442 = "cute.get_scalars"(%440) : (!cute.coord<"4096">) -> i32
      %443 = "arith.constant"() <{value = true}> : () -> i1
      %444 = "arith.cmpi"(%441, %442) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %445 = "arith.andi"(%443, %444) : (i1, i1) -> i1
      %446 = "arith.extui"(%445) : (i1) -> i8
      %447 = "cute.static"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%350, %447, %446) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %448 = "cute.static"() : () -> !cute.int_tuple<"(0,3072)">
      %449 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %450 = "cute.add_offset"(%449, %448) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %451 = "cute.make_view"(%450) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %452 = "cute.get_iter"(%451) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %453 = "cute.deref_arith_tuple_iter"(%452) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %454:2 = "cute.get_leaves"(%453) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %455 = "cute.make_coord"(%454#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %456 = "cute.static"() : () -> !cute.coord<"4096">
      %457 = "cute.get_scalars"(%455) : (!cute.coord<"?{div=8}">) -> i32
      %458 = "cute.get_scalars"(%456) : (!cute.coord<"4096">) -> i32
      %459 = "arith.constant"() <{value = true}> : () -> i1
      %460 = "arith.cmpi"(%457, %458) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %461 = "arith.andi"(%459, %460) : (i1, i1) -> i1
      %462 = "arith.extui"(%461) : (i1) -> i8
      %463 = "cute.static"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%350, %463, %462) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %464 = "cute.static"() : () -> !cute.int_tuple<"(0,3584)">
      %465 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %466 = "cute.add_offset"(%465, %464) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %467 = "cute.make_view"(%466) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %468 = "cute.get_iter"(%467) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %469 = "cute.deref_arith_tuple_iter"(%468) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %470:2 = "cute.get_leaves"(%469) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %471 = "cute.make_coord"(%470#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %472 = "cute.static"() : () -> !cute.coord<"4096">
      %473 = "cute.get_scalars"(%471) : (!cute.coord<"?{div=8}">) -> i32
      %474 = "cute.get_scalars"(%472) : (!cute.coord<"4096">) -> i32
      %475 = "arith.constant"() <{value = true}> : () -> i1
      %476 = "arith.cmpi"(%473, %474) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %477 = "arith.andi"(%475, %476) : (i1, i1) -> i1
      %478 = "arith.extui"(%477) : (i1) -> i8
      %479 = "cute.static"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%350, %479, %478) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %480 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %481 = "cute.make_view"(%190, %480) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
      %482 = "cute.get_iter"(%481) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %483 = "cute.make_view"(%482) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
      %484 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %485 = "cute.make_view"(%193, %484) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %486 = "cute.get_iter"(%485) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %487 = "cute.make_view"(%486) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
      %488 = "cute.static"() : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %489 = "cute.make_view"(%351, %488) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %490 = "cute.get_iter"(%489) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %491 = "cute.make_view"(%490) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %492 = "cute.static"() : () -> !cute.layout<"1:0">
      %493 = "cute.get_iter"(%483) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %494 = "cute.get_iter"(%487) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %495 = "cute.get_iter"(%491) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %496 = "cute.static"() : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %497 = "cute.static"() : () -> !cute.int_tuple<"1">
      %498 = "cute.get_scalars"(%497) : (!cute.int_tuple<"1">) -> i32
      %499 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %500 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%499, %498, %500) ({
      ^bb0(%arg13: i32):
        %776 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"(_,?)">
        %777 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,512))">
        %778 = "cute.static"() : () -> !cute.int_tuple<"0">
        %779 = "cute.add_offset"(%493, %778) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %780 = "cute.make_view"(%779, %777) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
        %781 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,8))">
        %782 = "cute.static"() : () -> !cute.int_tuple<"0">
        %783 = "cute.add_offset"(%494, %782) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %784 = "cute.make_view"(%783, %781) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
        %785 = "cute.static"() : () -> !cute.layout<"(8):(1)">
        %786 = "cute.crd2idx"(%776, %496) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %787 = "cute.add_offset"(%495, %786) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %788 = "cute.make_view"(%787, %785) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
        %789 = "cute.get_iter"(%780) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %790 = "cute.get_iter"(%784) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
        %791 = "cute.get_iter"(%788) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
        %792 = "builtin.unrealized_conversion_cast"(%791) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %793 = "llvm.load"(%792) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %794 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %795 = "llvm.icmp"(%793, %794) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%795) ({
          %887 = "builtin.unrealized_conversion_cast"(%789) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %888 = "builtin.unrealized_conversion_cast"(%790) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %889 = "llvm.load"(%887) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%889, %888) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %796 = "cute.static"() : () -> !cute.int_tuple<"1">
        %797 = "cute.add_offset"(%791, %796) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %798 = "builtin.unrealized_conversion_cast"(%797) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %799 = "llvm.load"(%798) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %800 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %801 = "llvm.icmp"(%799, %800) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%801) ({
          %880 = "cute.static"() : () -> !cute.int_tuple<"512">
          %881 = "cute.add_offset"(%789, %880) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %882 = "cute.static"() : () -> !cute.int_tuple<"8">
          %883 = "cute.add_offset"(%790, %882) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %884 = "builtin.unrealized_conversion_cast"(%881) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %885 = "builtin.unrealized_conversion_cast"(%883) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %886 = "llvm.load"(%884) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%886, %885) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %802 = "cute.static"() : () -> !cute.int_tuple<"2">
        %803 = "cute.add_offset"(%791, %802) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %804 = "builtin.unrealized_conversion_cast"(%803) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %805 = "llvm.load"(%804) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %806 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %807 = "llvm.icmp"(%805, %806) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%807) ({
          %873 = "cute.static"() : () -> !cute.int_tuple<"1024">
          %874 = "cute.add_offset"(%789, %873) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %875 = "cute.static"() : () -> !cute.int_tuple<"16">
          %876 = "cute.add_offset"(%790, %875) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %877 = "builtin.unrealized_conversion_cast"(%874) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %878 = "builtin.unrealized_conversion_cast"(%876) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %879 = "llvm.load"(%877) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%879, %878) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %808 = "cute.static"() : () -> !cute.int_tuple<"3">
        %809 = "cute.add_offset"(%791, %808) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %810 = "builtin.unrealized_conversion_cast"(%809) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %811 = "llvm.load"(%810) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %812 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %813 = "llvm.icmp"(%811, %812) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%813) ({
          %866 = "cute.static"() : () -> !cute.int_tuple<"1536">
          %867 = "cute.add_offset"(%789, %866) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %868 = "cute.static"() : () -> !cute.int_tuple<"24">
          %869 = "cute.add_offset"(%790, %868) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %870 = "builtin.unrealized_conversion_cast"(%867) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %871 = "builtin.unrealized_conversion_cast"(%869) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %872 = "llvm.load"(%870) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%872, %871) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %814 = "cute.static"() : () -> !cute.int_tuple<"4">
        %815 = "cute.add_offset"(%791, %814) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %816 = "builtin.unrealized_conversion_cast"(%815) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %817 = "llvm.load"(%816) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %818 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %819 = "llvm.icmp"(%817, %818) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%819) ({
          %859 = "cute.static"() : () -> !cute.int_tuple<"2048">
          %860 = "cute.add_offset"(%789, %859) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %861 = "cute.static"() : () -> !cute.int_tuple<"32">
          %862 = "cute.add_offset"(%790, %861) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %863 = "builtin.unrealized_conversion_cast"(%860) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %864 = "builtin.unrealized_conversion_cast"(%862) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %865 = "llvm.load"(%863) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%865, %864) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %820 = "cute.static"() : () -> !cute.int_tuple<"5">
        %821 = "cute.add_offset"(%791, %820) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %822 = "builtin.unrealized_conversion_cast"(%821) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %823 = "llvm.load"(%822) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %824 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %825 = "llvm.icmp"(%823, %824) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%825) ({
          %852 = "cute.static"() : () -> !cute.int_tuple<"2560">
          %853 = "cute.add_offset"(%789, %852) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %854 = "cute.static"() : () -> !cute.int_tuple<"40">
          %855 = "cute.add_offset"(%790, %854) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %856 = "builtin.unrealized_conversion_cast"(%853) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %857 = "builtin.unrealized_conversion_cast"(%855) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %858 = "llvm.load"(%856) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%858, %857) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %826 = "cute.static"() : () -> !cute.int_tuple<"6">
        %827 = "cute.add_offset"(%791, %826) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %828 = "builtin.unrealized_conversion_cast"(%827) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %829 = "llvm.load"(%828) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %830 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %831 = "llvm.icmp"(%829, %830) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%831) ({
          %845 = "cute.static"() : () -> !cute.int_tuple<"3072">
          %846 = "cute.add_offset"(%789, %845) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %847 = "cute.static"() : () -> !cute.int_tuple<"48">
          %848 = "cute.add_offset"(%790, %847) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %849 = "builtin.unrealized_conversion_cast"(%846) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %850 = "builtin.unrealized_conversion_cast"(%848) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %851 = "llvm.load"(%849) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%851, %850) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %832 = "cute.static"() : () -> !cute.int_tuple<"7">
        %833 = "cute.add_offset"(%791, %832) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %834 = "builtin.unrealized_conversion_cast"(%833) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %835 = "llvm.load"(%834) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %836 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %837 = "llvm.icmp"(%835, %836) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%837) ({
          %838 = "cute.static"() : () -> !cute.int_tuple<"3584">
          %839 = "cute.add_offset"(%789, %838) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %840 = "cute.static"() : () -> !cute.int_tuple<"56">
          %841 = "cute.add_offset"(%790, %840) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %842 = "builtin.unrealized_conversion_cast"(%839) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %843 = "builtin.unrealized_conversion_cast"(%841) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %844 = "llvm.load"(%842) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
          "llvm.store"(%844, %843) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %501 = "cute.get_iter"(%142) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %502 = "cute.make_view"(%501) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %503 = "cute.get_iter"(%175) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %504 = "cute.make_view"(%503) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %505 = "cute.get_iter"(%502) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %506 = "cute.make_view"(%505) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %507 = "cute.get_iter"(%504) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %508 = "cute.make_view"(%507) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %509 = "cute.static"() : () -> !cute.layout<"1:0">
      %510 = "cute.get_iter"(%506) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %511 = "cute.get_iter"(%508) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %512 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(512))">
      %513 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(8))">
      %514 = "cute.static"() : () -> !cute.int_tuple<"8">
      %515 = "cute.get_scalars"(%514) : (!cute.int_tuple<"8">) -> i32
      %516 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %517 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%516, %515, %517) ({
      ^bb0(%arg12: i32):
        %762 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"(_,?)">
        %763 = "cute.static"() : () -> !cute.layout<"(8):(1)">
        %764 = "cute.crd2idx"(%762, %512) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %765 = "cute.add_offset"(%510, %764) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %766 = "cute.make_view"(%765, %763) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %767 = "cute.static"() : () -> !cute.layout<"(8):(1)">
        %768 = "cute.crd2idx"(%762, %513) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %769 = "cute.add_offset"(%511, %768) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %770 = "cute.make_view"(%769, %767) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        %771 = "cute.get_iter"(%766) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
        %772 = "cute.get_iter"(%770) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<16>>
        %773 = "builtin.unrealized_conversion_cast"(%771) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %774 = "builtin.unrealized_conversion_cast"(%772) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %775 = "llvm.load"(%773) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%775, %774) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %518 = "cute.memref.load_vec"(%175) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %519 = "arith.extf"(%518) : (vector<64xbf16>) -> vector<64xf32>
      %520 = "arith.mulf"(%519, %519) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %521 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %522 = "vector.reduction"(%520, %521) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %523 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %524 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %525 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %526 = "nvvm.shfl.sync"(%523, %522, %524, %525) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %527 = "arith.addf"(%526, %522) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %528 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %529 = "nvvm.shfl.sync"(%523, %527, %528, %525) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %530 = "arith.addf"(%527, %529) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %531 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %532 = "nvvm.shfl.sync"(%523, %530, %531, %525) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %533 = "arith.addf"(%530, %532) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %534 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %535 = "nvvm.shfl.sync"(%523, %533, %534, %525) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %536 = "arith.addf"(%533, %535) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %537 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %538 = "nvvm.shfl.sync"(%523, %536, %537, %525) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %539 = "arith.addf"(%536, %538) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %540 = "nvvm.read.ptx.sreg.laneid"() : () -> i32
      %541 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %542 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %543 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %544 = "nvvm.read.ptx.sreg.ntid.x"() : () -> i32
      %545 = "nvvm.read.ptx.sreg.ntid.y"() : () -> i32
      %546 = "arith.muli"(%542, %544) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %547 = "arith.addi"(%541, %546) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %548 = "arith.muli"(%543, %544) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %549 = "arith.muli"(%548, %545) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %550 = "arith.addi"(%547, %549) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %551 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %552 = "arith.floordivsi"(%550, %551) : (i32, i32) -> i32
      %553 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %554 = "arith.floordivsi"(%552, %553) : (i32, i32) -> i32
      %555 = "arith.remsi"(%552, %553) : (i32, i32) -> i32
      %556 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %557 = "arith.cmpi"(%540, %556) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %558 = "scf.if"(%557) ({
        %761 = "cute.make_coord"(%554, %555) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%45, %761, %539) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"(%45) : (!memref_smem_f32_) -> ()
      }, {
        "scf.yield"(%45) : (!memref_smem_f32_) -> ()
      }) : (i1) -> !memref_smem_f32_
      %559 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%559) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %560 = "arith.cmpi"(%540, %553) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %561 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %562 = "scf.if"(%560) ({
        %759 = "cute.make_coord"(%554, %540) : (i32, i32) -> !cute.coord<"(?,?)">
        %760 = "cute.memref.load"(%558, %759) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%760) : (f32) -> ()
      }, {
        "scf.yield"(%561) : (f32) -> ()
      }) : (i1) -> f32
      %563 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %564 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %565 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %566 = "nvvm.shfl.sync"(%563, %562, %564, %565) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %567 = "arith.addf"(%562, %566) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %568 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %569 = "nvvm.shfl.sync"(%563, %567, %568, %565) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %570 = "arith.addf"(%567, %569) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %571 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %572 = "nvvm.shfl.sync"(%563, %570, %571, %565) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %573 = "arith.addf"(%570, %572) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %574 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %575 = "nvvm.shfl.sync"(%563, %573, %574, %565) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %576 = "arith.addf"(%573, %575) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %577 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %578 = "nvvm.shfl.sync"(%563, %576, %577, %565) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %579 = "arith.addf"(%576, %578) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %580 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %581 = "arith.divf"(%579, %580) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %582 = "arith.addf"(%581, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %583 = "math.rsqrt"(%582) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      %584 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%584) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %585 = "cute.get_iter"(%142) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %586 = "cute.make_view"(%585) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %587 = "cute.get_iter"(%175) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %588 = "cute.make_view"(%587) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %589 = "cute.get_iter"(%586) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %590 = "cute.make_view"(%589) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %591 = "cute.get_iter"(%588) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %592 = "cute.make_view"(%591) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %593 = "cute.static"() : () -> !cute.layout<"1:0">
      %594 = "cute.get_iter"(%590) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %595 = "cute.get_iter"(%592) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %596 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(512))">
      %597 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(8))">
      %598 = "cute.static"() : () -> !cute.int_tuple<"8">
      %599 = "cute.get_scalars"(%598) : (!cute.int_tuple<"8">) -> i32
      %600 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %601 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%600, %599, %601) ({
      ^bb0(%arg11: i32):
        %745 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %746 = "cute.static"() : () -> !cute.layout<"(8):(1)">
        %747 = "cute.crd2idx"(%745, %596) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %748 = "cute.add_offset"(%594, %747) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %749 = "cute.make_view"(%748, %746) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %750 = "cute.static"() : () -> !cute.layout<"(8):(1)">
        %751 = "cute.crd2idx"(%745, %597) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %752 = "cute.add_offset"(%595, %751) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %753 = "cute.make_view"(%752, %750) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        %754 = "cute.get_iter"(%749) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
        %755 = "cute.get_iter"(%753) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<16>>
        %756 = "builtin.unrealized_conversion_cast"(%754) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %757 = "builtin.unrealized_conversion_cast"(%755) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %758 = "llvm.load"(%756) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%758, %757) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %602 = "cute.memref.load_vec"(%175) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %603 = "arith.extf"(%602) : (vector<64xbf16>) -> vector<64xf32>
      %604 = "vector.broadcast"(%583) : (f32) -> vector<64xf32>
      %605 = "arith.mulf"(%603, %604) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %606 = "cute.memref.load_vec"(%195) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %607 = "arith.extf"(%606) : (vector<64xbf16>) -> vector<64xf32>
      %608 = "arith.mulf"(%605, %607) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %609 = "arith.truncf"(%608) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%609, %177) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%335) ({
        %610 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %611 = "cute.make_view"(%178, %610) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
        %612 = "cute.get_iter"(%611) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %613 = "cute.make_view"(%612) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
        %614 = "cute.static"() : () -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %615 = "cute.make_view"(%160, %614) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %616 = "cute.get_iter"(%615) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %617 = "cute.make_view"(%616) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %618 = "cute.static"() : () -> !cute.layout<"(8,1,1):(1,0,1)">
        %619 = "cute.make_view"(%198, %618) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %620 = "cute.get_iter"(%619) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %621 = "cute.make_view"(%620) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %622 = "cute.static"() : () -> !cute.layout<"1:0">
        %623 = "cute.get_iter"(%613) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %624 = "cute.get_iter"(%617) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %625 = "cute.get_iter"(%621) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %626 = "cute.static"() : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %627 = "cute.static"() : () -> !cute.int_tuple<"1">
        %628 = "cute.get_scalars"(%627) : (!cute.int_tuple<"1">) -> i32
        %629 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %630 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%629, %628, %630) ({
        ^bb0(%arg10: i32):
          %631 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
          %632 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,8))">
          %633 = "cute.static"() : () -> !cute.int_tuple<"0">
          %634 = "cute.add_offset"(%623, %633) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %635 = "cute.make_view"(%634, %632) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
          %636 = "cute.static"() : () -> !cute.layout<"((8,8)):((1,512))">
          %637 = "cute.static"() : () -> !cute.int_tuple<"0">
          %638 = "cute.add_offset"(%624, %637) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %639 = "cute.make_view"(%638, %636) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %640 = "cute.static"() : () -> !cute.layout<"(8):(1)">
          %641 = "cute.crd2idx"(%631, %626) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %642 = "cute.add_offset"(%625, %641) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %643 = "cute.make_view"(%642, %640) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          %644 = "cute.get_iter"(%635) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
          %645 = "cute.get_iter"(%639) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
          %646 = "cute.get_iter"(%643) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
          %647 = "builtin.unrealized_conversion_cast"(%646) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %648 = "llvm.load"(%647) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %649 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %650 = "llvm.icmp"(%648, %649) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%650) ({
            %742 = "builtin.unrealized_conversion_cast"(%644) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %743 = "builtin.unrealized_conversion_cast"(%645) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %744 = "llvm.load"(%742) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%744, %743) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %651 = "cute.static"() : () -> !cute.int_tuple<"1">
          %652 = "cute.add_offset"(%646, %651) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %653 = "builtin.unrealized_conversion_cast"(%652) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %654 = "llvm.load"(%653) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %655 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %656 = "llvm.icmp"(%654, %655) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%656) ({
            %735 = "cute.static"() : () -> !cute.int_tuple<"8">
            %736 = "cute.add_offset"(%644, %735) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %737 = "cute.static"() : () -> !cute.int_tuple<"512">
            %738 = "cute.add_offset"(%645, %737) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %739 = "builtin.unrealized_conversion_cast"(%736) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %740 = "builtin.unrealized_conversion_cast"(%738) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %741 = "llvm.load"(%739) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%741, %740) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %657 = "cute.static"() : () -> !cute.int_tuple<"2">
          %658 = "cute.add_offset"(%646, %657) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %659 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %660 = "llvm.load"(%659) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %661 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %662 = "llvm.icmp"(%660, %661) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%662) ({
            %728 = "cute.static"() : () -> !cute.int_tuple<"16">
            %729 = "cute.add_offset"(%644, %728) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %730 = "cute.static"() : () -> !cute.int_tuple<"1024">
            %731 = "cute.add_offset"(%645, %730) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %732 = "builtin.unrealized_conversion_cast"(%729) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %733 = "builtin.unrealized_conversion_cast"(%731) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %734 = "llvm.load"(%732) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%734, %733) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %663 = "cute.static"() : () -> !cute.int_tuple<"3">
          %664 = "cute.add_offset"(%646, %663) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %665 = "builtin.unrealized_conversion_cast"(%664) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %666 = "llvm.load"(%665) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %667 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %668 = "llvm.icmp"(%666, %667) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%668) ({
            %721 = "cute.static"() : () -> !cute.int_tuple<"24">
            %722 = "cute.add_offset"(%644, %721) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %723 = "cute.static"() : () -> !cute.int_tuple<"1536">
            %724 = "cute.add_offset"(%645, %723) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %725 = "builtin.unrealized_conversion_cast"(%722) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %726 = "builtin.unrealized_conversion_cast"(%724) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %727 = "llvm.load"(%725) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%727, %726) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %669 = "cute.static"() : () -> !cute.int_tuple<"4">
          %670 = "cute.add_offset"(%646, %669) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %671 = "builtin.unrealized_conversion_cast"(%670) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %672 = "llvm.load"(%671) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %673 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %674 = "llvm.icmp"(%672, %673) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%674) ({
            %714 = "cute.static"() : () -> !cute.int_tuple<"32">
            %715 = "cute.add_offset"(%644, %714) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %716 = "cute.static"() : () -> !cute.int_tuple<"2048">
            %717 = "cute.add_offset"(%645, %716) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %718 = "builtin.unrealized_conversion_cast"(%715) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %719 = "builtin.unrealized_conversion_cast"(%717) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %720 = "llvm.load"(%718) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%720, %719) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %675 = "cute.static"() : () -> !cute.int_tuple<"5">
          %676 = "cute.add_offset"(%646, %675) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %677 = "builtin.unrealized_conversion_cast"(%676) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %678 = "llvm.load"(%677) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %679 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %680 = "llvm.icmp"(%678, %679) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%680) ({
            %707 = "cute.static"() : () -> !cute.int_tuple<"40">
            %708 = "cute.add_offset"(%644, %707) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %709 = "cute.static"() : () -> !cute.int_tuple<"2560">
            %710 = "cute.add_offset"(%645, %709) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %711 = "builtin.unrealized_conversion_cast"(%708) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %712 = "builtin.unrealized_conversion_cast"(%710) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %713 = "llvm.load"(%711) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%713, %712) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %681 = "cute.static"() : () -> !cute.int_tuple<"6">
          %682 = "cute.add_offset"(%646, %681) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %683 = "builtin.unrealized_conversion_cast"(%682) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %684 = "llvm.load"(%683) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %685 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %686 = "llvm.icmp"(%684, %685) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%686) ({
            %700 = "cute.static"() : () -> !cute.int_tuple<"48">
            %701 = "cute.add_offset"(%644, %700) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %702 = "cute.static"() : () -> !cute.int_tuple<"3072">
            %703 = "cute.add_offset"(%645, %702) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %704 = "builtin.unrealized_conversion_cast"(%701) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
            %705 = "builtin.unrealized_conversion_cast"(%703) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %706 = "llvm.load"(%704) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%706, %705) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %687 = "cute.static"() : () -> !cute.int_tuple<"7">
          %688 = "cute.add_offset"(%646, %687) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %689 = "builtin.unrealized_conversion_cast"(%688) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %690 = "llvm.load"(%689) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %691 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %692 = "llvm.icmp"(%690, %691) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%692) ({
            %693 = "cute.static"() : () -> !cute.int_tuple<"56">
            %694 = "cute.add_offset"(%644, %693) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %695 = "cute.static"() : () -> !cute.int_tuple<"3584">
            %696 = "cute.add_offset"(%645, %695) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %697 = "builtin.unrealized_conversion_cast"(%694) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %698 = "builtin.unrealized_conversion_cast"(%696) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %699 = "llvm.load"(%697) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%699, %698) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
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
    %1 = "cute.static"() : () -> !cute.stride<"(4096,1)">
    %2 = "cute.make_layout"(%0, %1) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %3 = "cute.make_view"(%arg0, %2) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %4 = "cute.make_shape"(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %5 = "cute.static"() : () -> !cute.stride<"(4096,1)">
    %6 = "cute.make_layout"(%4, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %7 = "cute.make_view"(%arg2, %6) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %8 = "cute.static"() : () -> !cute.layout<"(4096):(1)">
    %9 = "cute.make_view"(%arg1, %8) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(4096):(1)">) -> !memref_gmem_bf16_1
    %10 = "cute.make_int_tuple"(%arg3) : (i32) -> !cute.int_tuple<"?">
    %11 = "cute.get_scalars"(%10) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
    %12 = "arith.constant"() <{value = 2 : i32}> : () -> i32
    %13 = "arith.ceildivsi"(%11, %12) : (i32, i32) -> i32
    %14 = "cute.make_int_tuple"(%13) : (i32) -> !cute.int_tuple<"?">
    %15 = "cute.get_leaves"(%14) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %16 = "cute.get_scalars"(%15) : (!cute.int_tuple<"?">) -> i32
    %17 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
    %18 = "arith.extsi"(%17) : (i32) -> i64
    %19 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %20 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %21 = "cuda.launch_cfg.create"(%19, %20, %20, %18, %16, %20, %20, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %22 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%21, %22) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %23 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%21, %23) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %24 = "cuda.launch_ex"(%21, %3, %9, %7, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %25 = "cuda.cast"(%24) : (!cuda.result) -> i32
    "cuda.return_if_error"(%25) : (i32) -> ()
    %26 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%26) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
