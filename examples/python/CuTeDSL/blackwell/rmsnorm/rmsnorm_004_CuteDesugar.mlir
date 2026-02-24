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
      "cf.assert"(%78) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16384 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
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
      "cf.assert"(%93) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16400 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %94 = "cute.recast_iter"(%75) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %95 = "cute.make_view"(%94, %83) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %96 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %97 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %98 = "cute.get_shape"(%97) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %99:2 = "cute.get_leaves"(%98) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %100 = "cute.to_int_tuple"(%99#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %101 = "cute.get_scalars"(%100) : (!cute.int_tuple<"?">) -> i32
      %102 = "cute.make_shape"(%100) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %103 = "cute.make_identity_tensor"(%102) : (!cute.shape<"(?,4096)">) -> !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %104 = "cute.get_iter"(%103) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %105 = "cute.deref_arith_tuple_iter"(%104) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %106:2 = "cute.get_leaves"(%105) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %107 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %108 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %109 = "cute.get_scalars"(%108) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %110 = "cute.make_coord"(%109) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %111 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %112 = "cute.get_scalars"(%111) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %113 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %114 = "arith.ceildivsi"(%112, %113) : (i32, i32) -> i32
      %115 = "cute.make_shape"(%114) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %116 = "cute.make_stride"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %117 = "cute.make_layout"(%115, %116) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %118 = "cute.crd2idx"(%110, %117) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %119 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %120 = "cute.add_offset"(%119, %118) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %121 = "cute.make_view"(%120) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %122 = "cute.get_iter"(%121) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %123 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %124 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %125 = "cute.get_scalars"(%124) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %126 = "cute.make_coord"(%125) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %127 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %128 = "cute.get_scalars"(%127) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %129 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %130 = "arith.ceildivsi"(%128, %129) : (i32, i32) -> i32
      %131 = "cute.make_shape"(%130) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %132 = "cute.make_stride"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %133 = "cute.make_layout"(%131, %132) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %134 = "cute.crd2idx"(%126, %133) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %135 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %136 = "cute.add_offset"(%135, %134) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %137 = "cute.make_view"(%136) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_2
      %138 = "cute.get_iter"(%137) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %139 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %140 = "cute.make_coord"(%55) : (i32) -> !cute.coord<"(?,0)">
      %141 = "cute.get_scalars"(%140) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %142 = "cute.make_coord"(%141) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %143 = "cute.get_layout"(%103) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %144 = "cute.get_scalars"(%143) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %145 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %146 = "arith.ceildivsi"(%144, %145) : (i32, i32) -> i32
      %147 = "cute.make_shape"(%146) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %148 = "cute.make_stride"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %149 = "cute.make_layout"(%147, %148) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %150 = "cute.crd2idx"(%142, %149) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %151 = "cute.get_iter"(%103) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %152 = "cute.add_offset"(%151, %150) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %153 = "cute.make_view"(%152) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %154 = "cute.get_iter"(%153) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %155 = "cute.deref_arith_tuple_iter"(%154) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %156:2 = "cute.get_leaves"(%155) : (!cute.int_tuple<"(?{div=2},0)">) -> (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"0">)
      %157 = "cute.get_scalars"(%156#0) : (!cute.int_tuple<"?{div=2}">) -> i32
      %158 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %159 = "cute.make_shape"() : () -> !cute.shape<"(2)">
      %160 = "cute.make_stride"() : () -> !cute.stride<"(0)">
      %161 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(2):(0)">
      %162 = "cute.get_shape"(%158) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %163 = "cute.get_leaves"(%162) : (!cute.shape<"(4096)">) -> !cute.shape<"4096">
      %164 = "cute.prepend_to_rank"(%158, %161) <{rank = 2 : si32}> : (!cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">) -> !cute.layout<"((2),4096):((0),1)">
      %165 = "cute.make_view"(%44, %164) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((2),4096):((0),1)">) -> !memref_gmem_bf16_3
      %166 = "cute.get_iter"(%165) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %167 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %168 = "cute.make_coord"() : () -> !cute.coord<"(0,0)">
      %169 = "cute.make_coord"() : () -> !cute.coord<"((_,_),(0,0))">
      %170 = "cute.get_layout"(%165) : (!memref_gmem_bf16_3) -> !cute.layout<"((2),4096):((0),1)">
      %171 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">
      %172 = "cute.crd2idx"(%169, %171) : (!cute.coord<"((_,_),(0,0))">, !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">) -> !cute.int_tuple<"0">
      %173 = "cute.get_iter"(%165) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %174 = "cute.add_offset"(%173, %172) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %175 = "cute.make_view"(%174) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_4
      %176 = "cute.get_iter"(%175) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %177 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %178 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %179 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %180 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %181 = "cute.make_tiled_copy"(%177) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %182 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %183 = "cute.make_tiled_copy"(%178) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %184 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %185 = "cute.make_tiled_copy"(%179) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %186 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %187 = "cute.tiled.copy.partition_S"(%181, %121, %186) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %188 = "cute.get_iter"(%187) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %189 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %190 = "cute.tiled.copy.partition_D"(%181, %80, %189) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %191 = "cute.get_iter"(%190) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %192 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %193 = "cute.tiled.copy.partition_D"(%185, %137, %192) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %194 = "cute.get_iter"(%193) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %195 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %196 = "cute.tiled.copy.partition_S"(%181, %153, %195) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %197 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %198 = "cute.deref_arith_tuple_iter"(%197) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %199:2 = "cute.get_leaves"(%198) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %200 = "cute.get_scalars"(%199#0) : (!cute.int_tuple<"?">) -> i32
      %201 = "cute.get_scalars"(%199#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %202 = "cute.get_layout"(%187) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %203 = "cute.make_layout_like"(%202) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %204 = "cute.memref.alloca"(%203) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %205 = "cute.get_iter"(%204) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %206 = "cute.get_iter"(%204) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %207 = "cute.get_layout"(%193) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %208 = "cute.make_layout_like"(%207) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %209 = "cute.memref.alloca"(%208) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %210 = "cute.get_iter"(%209) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %211 = "cute.get_iter"(%209) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %212 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %213 = "cute.tiled.copy.partition_S"(%183, %175, %212) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %214 = "cute.get_iter"(%213) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %215 = "cute.get_layout"(%213) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %216 = "cute.make_layout_like"(%215) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %217 = "cute.memref.alloca"(%216) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %218 = "cute.get_iter"(%217) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %219 = "cute.get_iter"(%217) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %220 = "cute.tiled.copy.retile"(%181, %217) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %221 = "cute.get_iter"(%220) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %222 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %223 = "cute.size"(%222) <{mode = array<i32: 0, 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %224 = "cute.get_leaves"(%223) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %225 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %226 = "cute.size"(%225) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %227 = "cute.get_leaves"(%226) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %228 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %229 = "cute.size"(%228) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %230 = "cute.get_leaves"(%229) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %231 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %232 = "cute.size"(%231) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %233 = "cute.get_leaves"(%232) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %234 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %235 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %236 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %237 = "cute.memref.alloca"(%236) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %238 = "cute.get_iter"(%237) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %239 = "cute.get_iter"(%237) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %240 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %241 = "cute.get_shape"(%240) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %242:3 = "cute.get_leaves"(%241) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %243 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %244 = "cute.get_shape"(%243) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %245:3 = "cute.get_leaves"(%244) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %246 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %247 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %248 = "cute.crd2idx"(%246, %247) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %249 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %250 = "cute.add_offset"(%249, %248) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %251 = "cute.make_view"(%250) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %252 = "cute.get_iter"(%251) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %253 = "cute.deref_arith_tuple_iter"(%252) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %254:2 = "cute.get_leaves"(%253) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %255 = "cute.get_scalars"(%254#0) : (!cute.int_tuple<"?">) -> i32
      %256 = "cute.get_scalars"(%254#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %257 = "cute.get_iter"(%251) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %258 = "cute.deref_arith_tuple_iter"(%257) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %259:2 = "cute.get_leaves"(%258) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %260 = "cute.get_scalars"(%259#0) : (!cute.int_tuple<"?">) -> i32
      %261 = "cute.get_scalars"(%259#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %262 = "cute.get_iter"(%251) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %263 = "cute.deref_arith_tuple_iter"(%262) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %264:2 = "cute.get_leaves"(%263) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %265 = "cute.get_scalars"(%264#0) : (!cute.int_tuple<"?">) -> i32
      %266 = "cute.get_scalars"(%264#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %267 = "cute.make_coord"(%264#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %268 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %269 = "cute.elem_less"(%267, %268) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %270 = "arith.extui"(%269) : (i1) -> i8
      %271 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%237, %271, %270) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %272 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %273 = "cute.get_shape"(%272) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %274:3 = "cute.get_leaves"(%273) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %275 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %276 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %277 = "cute.crd2idx"(%275, %276) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %278 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %279 = "cute.add_offset"(%278, %277) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %280 = "cute.make_view"(%279) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %281 = "cute.get_iter"(%280) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %282 = "cute.deref_arith_tuple_iter"(%281) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %283:2 = "cute.get_leaves"(%282) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %284 = "cute.get_scalars"(%283#0) : (!cute.int_tuple<"?">) -> i32
      %285 = "cute.get_scalars"(%283#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %286 = "cute.get_iter"(%280) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %287 = "cute.deref_arith_tuple_iter"(%286) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %288:2 = "cute.get_leaves"(%287) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %289 = "cute.get_scalars"(%288#0) : (!cute.int_tuple<"?">) -> i32
      %290 = "cute.get_scalars"(%288#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %291 = "cute.get_iter"(%280) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %292 = "cute.deref_arith_tuple_iter"(%291) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %293:2 = "cute.get_leaves"(%292) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %294 = "cute.get_scalars"(%293#0) : (!cute.int_tuple<"?">) -> i32
      %295 = "cute.get_scalars"(%293#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %296 = "cute.make_coord"(%293#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %297 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %298 = "cute.elem_less"(%296, %297) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %299 = "arith.extui"(%298) : (i1) -> i8
      %300 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%237, %300, %299) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %301 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %302 = "cute.get_shape"(%301) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %303:3 = "cute.get_leaves"(%302) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %304 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %305 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %306 = "cute.crd2idx"(%304, %305) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %307 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %308 = "cute.add_offset"(%307, %306) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %309 = "cute.make_view"(%308) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %310 = "cute.get_iter"(%309) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %311 = "cute.deref_arith_tuple_iter"(%310) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %312:2 = "cute.get_leaves"(%311) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %313 = "cute.get_scalars"(%312#0) : (!cute.int_tuple<"?">) -> i32
      %314 = "cute.get_scalars"(%312#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %315 = "cute.get_iter"(%309) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %316 = "cute.deref_arith_tuple_iter"(%315) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %317:2 = "cute.get_leaves"(%316) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %318 = "cute.get_scalars"(%317#0) : (!cute.int_tuple<"?">) -> i32
      %319 = "cute.get_scalars"(%317#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %320 = "cute.get_iter"(%309) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %321 = "cute.deref_arith_tuple_iter"(%320) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %322:2 = "cute.get_leaves"(%321) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %323 = "cute.get_scalars"(%322#0) : (!cute.int_tuple<"?">) -> i32
      %324 = "cute.get_scalars"(%322#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %325 = "cute.make_coord"(%322#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %326 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %327 = "cute.elem_less"(%325, %326) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %328 = "arith.extui"(%327) : (i1) -> i8
      %329 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%237, %329, %328) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %330 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %331 = "cute.get_shape"(%330) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %332:3 = "cute.get_leaves"(%331) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %333 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %334 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %335 = "cute.crd2idx"(%333, %334) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %336 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %337 = "cute.add_offset"(%336, %335) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %338 = "cute.make_view"(%337) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %339 = "cute.get_iter"(%338) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %340 = "cute.deref_arith_tuple_iter"(%339) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %341:2 = "cute.get_leaves"(%340) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %342 = "cute.get_scalars"(%341#0) : (!cute.int_tuple<"?">) -> i32
      %343 = "cute.get_scalars"(%341#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %344 = "cute.get_iter"(%338) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %345 = "cute.deref_arith_tuple_iter"(%344) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %346:2 = "cute.get_leaves"(%345) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %347 = "cute.get_scalars"(%346#0) : (!cute.int_tuple<"?">) -> i32
      %348 = "cute.get_scalars"(%346#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %349 = "cute.get_iter"(%338) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %350 = "cute.deref_arith_tuple_iter"(%349) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %351:2 = "cute.get_leaves"(%350) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %352 = "cute.get_scalars"(%351#0) : (!cute.int_tuple<"?">) -> i32
      %353 = "cute.get_scalars"(%351#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %354 = "cute.make_coord"(%351#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %355 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %356 = "cute.elem_less"(%354, %355) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %357 = "arith.extui"(%356) : (i1) -> i8
      %358 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%237, %358, %357) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %359 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %360 = "cute.get_shape"(%359) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %361:3 = "cute.get_leaves"(%360) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %362 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %363 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %364 = "cute.crd2idx"(%362, %363) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %365 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %366 = "cute.add_offset"(%365, %364) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %367 = "cute.make_view"(%366) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %368 = "cute.get_iter"(%367) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %369 = "cute.deref_arith_tuple_iter"(%368) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %370:2 = "cute.get_leaves"(%369) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %371 = "cute.get_scalars"(%370#0) : (!cute.int_tuple<"?">) -> i32
      %372 = "cute.get_scalars"(%370#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %373 = "cute.get_iter"(%367) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %374 = "cute.deref_arith_tuple_iter"(%373) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %375:2 = "cute.get_leaves"(%374) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %376 = "cute.get_scalars"(%375#0) : (!cute.int_tuple<"?">) -> i32
      %377 = "cute.get_scalars"(%375#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %378 = "cute.get_iter"(%367) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %379 = "cute.deref_arith_tuple_iter"(%378) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %380:2 = "cute.get_leaves"(%379) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %381 = "cute.get_scalars"(%380#0) : (!cute.int_tuple<"?">) -> i32
      %382 = "cute.get_scalars"(%380#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %383 = "cute.make_coord"(%380#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %384 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %385 = "cute.elem_less"(%383, %384) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %386 = "arith.extui"(%385) : (i1) -> i8
      %387 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%237, %387, %386) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %388 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %389 = "cute.get_shape"(%388) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %390:3 = "cute.get_leaves"(%389) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %391 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %392 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %393 = "cute.crd2idx"(%391, %392) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %394 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %395 = "cute.add_offset"(%394, %393) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %396 = "cute.make_view"(%395) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %397 = "cute.get_iter"(%396) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %398 = "cute.deref_arith_tuple_iter"(%397) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %399:2 = "cute.get_leaves"(%398) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %400 = "cute.get_scalars"(%399#0) : (!cute.int_tuple<"?">) -> i32
      %401 = "cute.get_scalars"(%399#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %402 = "cute.get_iter"(%396) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %403 = "cute.deref_arith_tuple_iter"(%402) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %404:2 = "cute.get_leaves"(%403) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %405 = "cute.get_scalars"(%404#0) : (!cute.int_tuple<"?">) -> i32
      %406 = "cute.get_scalars"(%404#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %407 = "cute.get_iter"(%396) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %408 = "cute.deref_arith_tuple_iter"(%407) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %409:2 = "cute.get_leaves"(%408) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %410 = "cute.get_scalars"(%409#0) : (!cute.int_tuple<"?">) -> i32
      %411 = "cute.get_scalars"(%409#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %412 = "cute.make_coord"(%409#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %413 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %414 = "cute.elem_less"(%412, %413) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %415 = "arith.extui"(%414) : (i1) -> i8
      %416 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%237, %416, %415) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %417 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %418 = "cute.get_shape"(%417) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %419:3 = "cute.get_leaves"(%418) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %420 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %421 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %422 = "cute.crd2idx"(%420, %421) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %423 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %424 = "cute.add_offset"(%423, %422) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %425 = "cute.make_view"(%424) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %426 = "cute.get_iter"(%425) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %427 = "cute.deref_arith_tuple_iter"(%426) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %428:2 = "cute.get_leaves"(%427) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %429 = "cute.get_scalars"(%428#0) : (!cute.int_tuple<"?">) -> i32
      %430 = "cute.get_scalars"(%428#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %431 = "cute.get_iter"(%425) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %432 = "cute.deref_arith_tuple_iter"(%431) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %433:2 = "cute.get_leaves"(%432) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %434 = "cute.get_scalars"(%433#0) : (!cute.int_tuple<"?">) -> i32
      %435 = "cute.get_scalars"(%433#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %436 = "cute.get_iter"(%425) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %437 = "cute.deref_arith_tuple_iter"(%436) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %438:2 = "cute.get_leaves"(%437) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %439 = "cute.get_scalars"(%438#0) : (!cute.int_tuple<"?">) -> i32
      %440 = "cute.get_scalars"(%438#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %441 = "cute.make_coord"(%438#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %442 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %443 = "cute.elem_less"(%441, %442) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %444 = "arith.extui"(%443) : (i1) -> i8
      %445 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%237, %445, %444) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %446 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %447 = "cute.get_shape"(%446) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %448:3 = "cute.get_leaves"(%447) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %449 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %450 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %451 = "cute.crd2idx"(%449, %450) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %452 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %453 = "cute.add_offset"(%452, %451) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %454 = "cute.make_view"(%453) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %455 = "cute.get_iter"(%454) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %456 = "cute.deref_arith_tuple_iter"(%455) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %457:2 = "cute.get_leaves"(%456) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %458 = "cute.get_scalars"(%457#0) : (!cute.int_tuple<"?">) -> i32
      %459 = "cute.get_scalars"(%457#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %460 = "cute.get_iter"(%454) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %461 = "cute.deref_arith_tuple_iter"(%460) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %462:2 = "cute.get_leaves"(%461) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %463 = "cute.get_scalars"(%462#0) : (!cute.int_tuple<"?">) -> i32
      %464 = "cute.get_scalars"(%462#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %465 = "cute.get_iter"(%454) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %466 = "cute.deref_arith_tuple_iter"(%465) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %467:2 = "cute.get_leaves"(%466) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %468 = "cute.get_scalars"(%467#0) : (!cute.int_tuple<"?">) -> i32
      %469 = "cute.get_scalars"(%467#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %470 = "cute.make_coord"(%467#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %471 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %472 = "cute.elem_less"(%470, %471) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %473 = "arith.extui"(%472) : (i1) -> i8
      %474 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%237, %474, %473) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %475 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %476 = "cute.get_layout"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %477 = "cute.crd2idx"(%475, %476) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %478 = "cute.get_iter"(%196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %479 = "cute.add_offset"(%478, %477) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %480 = "cute.make_view"(%479) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %481 = "cute.get_iter"(%480) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %482 = "cute.deref_arith_tuple_iter"(%481) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %483:2 = "cute.get_leaves"(%482) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %484 = "cute.get_scalars"(%483#0) : (!cute.int_tuple<"?">) -> i32
      %485 = "cute.get_scalars"(%483#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %486 = "cute.get_iter"(%480) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %487 = "cute.deref_arith_tuple_iter"(%486) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %488:2 = "cute.get_leaves"(%487) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %489 = "cute.get_scalars"(%488#0) : (!cute.int_tuple<"?">) -> i32
      %490 = "cute.get_scalars"(%488#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %491 = "cute.get_iter"(%480) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %492 = "cute.deref_arith_tuple_iter"(%491) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %493:2 = "cute.get_leaves"(%492) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %494 = "cute.get_scalars"(%493#0) : (!cute.int_tuple<"?">) -> i32
      %495 = "cute.get_scalars"(%493#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %496 = "arith.cmpi"(%494, %62) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%496) ({
        %1204 = "cute.get_layout"(%187) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1205 = "cute.get_shape"(%1204) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1206:4 = "cute.get_leaves"(%1205) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1207 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1208 = "cute.get_shape"(%1207) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1209:4 = "cute.get_leaves"(%1208) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1210 = "cute.get_layout"(%187) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1211 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1212 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1213 = "cute.append_to_rank"(%1210, %1212) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1214 = "cute.make_view"(%188, %1213) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %1215 = "cute.get_iter"(%1214) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1216 = "cute.get_layout"(%1214) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1217 = "cute.get_shape"(%1216) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1218:4 = "cute.get_leaves"(%1217) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1219 = "cute.get_layout"(%1214) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1220 = "cute.get_shape"(%1219) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1221:4 = "cute.get_leaves"(%1220) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1222 = "cute.get_iter"(%1214) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1223 = "cute.make_view"(%1222) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %1224 = "cute.get_iter"(%1223) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1225 = "cute.get_iter"(%1223) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1226 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1227 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1228 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1229 = "cute.append_to_rank"(%1226, %1228) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1230 = "cute.make_view"(%191, %1229) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_smem_bf16_1
        %1231 = "cute.get_iter"(%1230) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %1232 = "cute.get_layout"(%1230) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1233 = "cute.get_shape"(%1232) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1234:4 = "cute.get_leaves"(%1233) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1235 = "cute.get_layout"(%1230) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1236 = "cute.get_shape"(%1235) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1237:4 = "cute.get_leaves"(%1236) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1238 = "cute.get_iter"(%1230) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %1239 = "cute.make_view"(%1238) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_2
        %1240 = "cute.get_iter"(%1239) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1241 = "cute.get_iter"(%1239) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1242 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1243 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1244 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1245 = "cute.append_to_rank"(%1242, %1244) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1246 = "cute.make_view"(%239, %1245) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1247 = "cute.get_iter"(%1246) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1248 = "cute.get_layout"(%1246) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1249 = "cute.get_shape"(%1248) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1250:3 = "cute.get_leaves"(%1249) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1251 = "cute.get_layout"(%1246) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1252 = "cute.get_shape"(%1251) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1253:3 = "cute.get_leaves"(%1252) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1254 = "cute.get_iter"(%1246) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1255 = "cute.make_view"(%1254) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1256 = "cute.get_iter"(%1255) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1257 = "cute.get_iter"(%1255) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1258 = "cute.get_layout"(%1223) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1259 = "cute.get_shape"(%1258) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1260:4 = "cute.get_leaves"(%1259) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1261 = "cute.get_layout"(%1239) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1262 = "cute.get_shape"(%1261) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1263:4 = "cute.get_leaves"(%1262) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1264 = "cute.get_layout"(%1223) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1265 = "cute.size"(%1264) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1266 = "cute.get_leaves"(%1265) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1267 = "cute.get_layout"(%1239) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1268 = "cute.size"(%1267) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1269 = "cute.get_leaves"(%1268) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1270 = "cute.static"() : () -> !cute.layout<"1:0">
        %1271 = "cute.get_iter"(%1223) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1272 = "cute.get_iter"(%1239) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %1273 = "cute.get_layout"(%1223) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1274 = "cute.get_layout"(%1239) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1275 = "cute.append_to_rank"(%1273, %1270) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1276 = "cute.append_to_rank"(%1274, %1270) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1277 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1278 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1279 = "cute.get_iter"(%1255) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1280 = "cute.get_layout"(%1255) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1281 = "cute.append_to_rank"(%1280, %1270) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1282 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %1283 = "cute.size"(%1277) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
        %1284 = "cute.get_scalars"(%1283) : (!cute.int_tuple<"1">) -> i32
        %1285 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1286 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1285, %1284, %1286) ({
        ^bb0(%arg14: i32):
          %1287 = "cute.make_coord"(%arg14) : (i32) -> !cute.coord<"(_,?)">
          %1288 = "cute.slice"(%1277, %1287) : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,512))">
          %1289 = "cute.crd2idx"(%1287, %1277) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1290 = "cute.add_offset"(%1271, %1289) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %1291 = "cute.make_view"(%1290, %1288) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %1292 = "cute.slice"(%1278, %1287) : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,512))">
          %1293 = "cute.crd2idx"(%1287, %1278) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1294 = "cute.add_offset"(%1272, %1293) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %1295 = "cute.make_view"(%1294, %1292) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_smem_bf16_3
          %1296 = "cute.slice"(%1282, %1287) : (!cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
          %1297 = "cute.crd2idx"(%1287, %1282) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %1298 = "cute.add_offset"(%1279, %1297) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1299 = "cute.make_view"(%1298, %1296) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          "cute.copy_atom_call"(%177, %1291, %1295, %1299) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_7, !memref_smem_bf16_3, !memref_rmem_i8_2) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %497 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"?">
      %498 = "cute.tiled.copy.partition_S"(%183, %153, %497) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %499 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %500 = "cute.deref_arith_tuple_iter"(%499) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %501:2 = "cute.get_leaves"(%500) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %502 = "cute.get_scalars"(%501#0) : (!cute.int_tuple<"?">) -> i32
      %503 = "cute.get_scalars"(%501#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %504 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %505 = "cute.size"(%504) <{mode = array<i32: 0, 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %506 = "cute.get_leaves"(%505) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %507 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %508 = "cute.size"(%507) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %509 = "cute.get_leaves"(%508) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %510 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %511 = "cute.size"(%510) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %512 = "cute.get_leaves"(%511) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %513 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %514 = "cute.size"(%513) <{mode = array<i32: 2>}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %515 = "cute.get_leaves"(%514) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %516 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %517 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %518 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,1,1):(1,0,1)">
      %519 = "cute.memref.alloca"(%518) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %520 = "cute.get_iter"(%519) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %521 = "cute.get_iter"(%519) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %522 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %523 = "cute.get_shape"(%522) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %524:3 = "cute.get_leaves"(%523) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %525 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %526 = "cute.get_shape"(%525) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %527:3 = "cute.get_leaves"(%526) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %528 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %529 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %530 = "cute.crd2idx"(%528, %529) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %531 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %532 = "cute.add_offset"(%531, %530) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %533 = "cute.make_view"(%532) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %534 = "cute.get_iter"(%533) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %535 = "cute.deref_arith_tuple_iter"(%534) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %536:2 = "cute.get_leaves"(%535) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %537 = "cute.get_scalars"(%536#0) : (!cute.int_tuple<"?">) -> i32
      %538 = "cute.get_scalars"(%536#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %539 = "cute.get_iter"(%533) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %540 = "cute.deref_arith_tuple_iter"(%539) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %541:2 = "cute.get_leaves"(%540) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %542 = "cute.get_scalars"(%541#0) : (!cute.int_tuple<"?">) -> i32
      %543 = "cute.get_scalars"(%541#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %544 = "cute.get_iter"(%533) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %545 = "cute.deref_arith_tuple_iter"(%544) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %546:2 = "cute.get_leaves"(%545) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %547 = "cute.get_scalars"(%546#0) : (!cute.int_tuple<"?">) -> i32
      %548 = "cute.get_scalars"(%546#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %549 = "cute.make_coord"(%546#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %550 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %551 = "cute.elem_less"(%549, %550) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %552 = "arith.extui"(%551) : (i1) -> i8
      %553 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%519, %553, %552) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %554 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %555 = "cute.get_shape"(%554) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %556:3 = "cute.get_leaves"(%555) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %557 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %558 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %559 = "cute.crd2idx"(%557, %558) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %560 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %561 = "cute.add_offset"(%560, %559) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %562 = "cute.make_view"(%561) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %563 = "cute.get_iter"(%562) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %564 = "cute.deref_arith_tuple_iter"(%563) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %565:2 = "cute.get_leaves"(%564) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %566 = "cute.get_scalars"(%565#0) : (!cute.int_tuple<"?">) -> i32
      %567 = "cute.get_scalars"(%565#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %568 = "cute.get_iter"(%562) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %569 = "cute.deref_arith_tuple_iter"(%568) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %570:2 = "cute.get_leaves"(%569) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %571 = "cute.get_scalars"(%570#0) : (!cute.int_tuple<"?">) -> i32
      %572 = "cute.get_scalars"(%570#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %573 = "cute.get_iter"(%562) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %574 = "cute.deref_arith_tuple_iter"(%573) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %575:2 = "cute.get_leaves"(%574) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %576 = "cute.get_scalars"(%575#0) : (!cute.int_tuple<"?">) -> i32
      %577 = "cute.get_scalars"(%575#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %578 = "cute.make_coord"(%575#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %579 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %580 = "cute.elem_less"(%578, %579) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %581 = "arith.extui"(%580) : (i1) -> i8
      %582 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%519, %582, %581) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %583 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %584 = "cute.get_shape"(%583) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %585:3 = "cute.get_leaves"(%584) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %586 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %587 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %588 = "cute.crd2idx"(%586, %587) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %589 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %590 = "cute.add_offset"(%589, %588) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %591 = "cute.make_view"(%590) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %592 = "cute.get_iter"(%591) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %593 = "cute.deref_arith_tuple_iter"(%592) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %594:2 = "cute.get_leaves"(%593) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %595 = "cute.get_scalars"(%594#0) : (!cute.int_tuple<"?">) -> i32
      %596 = "cute.get_scalars"(%594#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %597 = "cute.get_iter"(%591) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %598 = "cute.deref_arith_tuple_iter"(%597) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %599:2 = "cute.get_leaves"(%598) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %600 = "cute.get_scalars"(%599#0) : (!cute.int_tuple<"?">) -> i32
      %601 = "cute.get_scalars"(%599#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %602 = "cute.get_iter"(%591) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %603 = "cute.deref_arith_tuple_iter"(%602) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %604:2 = "cute.get_leaves"(%603) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %605 = "cute.get_scalars"(%604#0) : (!cute.int_tuple<"?">) -> i32
      %606 = "cute.get_scalars"(%604#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %607 = "cute.make_coord"(%604#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %608 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %609 = "cute.elem_less"(%607, %608) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %610 = "arith.extui"(%609) : (i1) -> i8
      %611 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%519, %611, %610) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %612 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %613 = "cute.get_shape"(%612) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %614:3 = "cute.get_leaves"(%613) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %615 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %616 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %617 = "cute.crd2idx"(%615, %616) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %618 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %619 = "cute.add_offset"(%618, %617) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %620 = "cute.make_view"(%619) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %621 = "cute.get_iter"(%620) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %622 = "cute.deref_arith_tuple_iter"(%621) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %623:2 = "cute.get_leaves"(%622) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %624 = "cute.get_scalars"(%623#0) : (!cute.int_tuple<"?">) -> i32
      %625 = "cute.get_scalars"(%623#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %626 = "cute.get_iter"(%620) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %627 = "cute.deref_arith_tuple_iter"(%626) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %628:2 = "cute.get_leaves"(%627) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %629 = "cute.get_scalars"(%628#0) : (!cute.int_tuple<"?">) -> i32
      %630 = "cute.get_scalars"(%628#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %631 = "cute.get_iter"(%620) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %632 = "cute.deref_arith_tuple_iter"(%631) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %633:2 = "cute.get_leaves"(%632) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %634 = "cute.get_scalars"(%633#0) : (!cute.int_tuple<"?">) -> i32
      %635 = "cute.get_scalars"(%633#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %636 = "cute.make_coord"(%633#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %637 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %638 = "cute.elem_less"(%636, %637) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %639 = "arith.extui"(%638) : (i1) -> i8
      %640 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%519, %640, %639) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %641 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %642 = "cute.get_shape"(%641) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %643:3 = "cute.get_leaves"(%642) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %644 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %645 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %646 = "cute.crd2idx"(%644, %645) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %647 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %648 = "cute.add_offset"(%647, %646) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %649 = "cute.make_view"(%648) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %650 = "cute.get_iter"(%649) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %651 = "cute.deref_arith_tuple_iter"(%650) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %652:2 = "cute.get_leaves"(%651) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %653 = "cute.get_scalars"(%652#0) : (!cute.int_tuple<"?">) -> i32
      %654 = "cute.get_scalars"(%652#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %655 = "cute.get_iter"(%649) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %656 = "cute.deref_arith_tuple_iter"(%655) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %657:2 = "cute.get_leaves"(%656) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %658 = "cute.get_scalars"(%657#0) : (!cute.int_tuple<"?">) -> i32
      %659 = "cute.get_scalars"(%657#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %660 = "cute.get_iter"(%649) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %661 = "cute.deref_arith_tuple_iter"(%660) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %662:2 = "cute.get_leaves"(%661) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %663 = "cute.get_scalars"(%662#0) : (!cute.int_tuple<"?">) -> i32
      %664 = "cute.get_scalars"(%662#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %665 = "cute.make_coord"(%662#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %666 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %667 = "cute.elem_less"(%665, %666) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %668 = "arith.extui"(%667) : (i1) -> i8
      %669 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%519, %669, %668) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %670 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %671 = "cute.get_shape"(%670) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %672:3 = "cute.get_leaves"(%671) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %673 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %674 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %675 = "cute.crd2idx"(%673, %674) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %676 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %677 = "cute.add_offset"(%676, %675) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %678 = "cute.make_view"(%677) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %679 = "cute.get_iter"(%678) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %680 = "cute.deref_arith_tuple_iter"(%679) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %681:2 = "cute.get_leaves"(%680) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %682 = "cute.get_scalars"(%681#0) : (!cute.int_tuple<"?">) -> i32
      %683 = "cute.get_scalars"(%681#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %684 = "cute.get_iter"(%678) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %685 = "cute.deref_arith_tuple_iter"(%684) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %686:2 = "cute.get_leaves"(%685) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %687 = "cute.get_scalars"(%686#0) : (!cute.int_tuple<"?">) -> i32
      %688 = "cute.get_scalars"(%686#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %689 = "cute.get_iter"(%678) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %690 = "cute.deref_arith_tuple_iter"(%689) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %691:2 = "cute.get_leaves"(%690) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %692 = "cute.get_scalars"(%691#0) : (!cute.int_tuple<"?">) -> i32
      %693 = "cute.get_scalars"(%691#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %694 = "cute.make_coord"(%691#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %695 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %696 = "cute.elem_less"(%694, %695) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %697 = "arith.extui"(%696) : (i1) -> i8
      %698 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%519, %698, %697) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %699 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %700 = "cute.get_shape"(%699) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %701:3 = "cute.get_leaves"(%700) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %702 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %703 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %704 = "cute.crd2idx"(%702, %703) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %705 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %706 = "cute.add_offset"(%705, %704) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %707 = "cute.make_view"(%706) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %708 = "cute.get_iter"(%707) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %709 = "cute.deref_arith_tuple_iter"(%708) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %710:2 = "cute.get_leaves"(%709) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %711 = "cute.get_scalars"(%710#0) : (!cute.int_tuple<"?">) -> i32
      %712 = "cute.get_scalars"(%710#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %713 = "cute.get_iter"(%707) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %714 = "cute.deref_arith_tuple_iter"(%713) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %715:2 = "cute.get_leaves"(%714) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %716 = "cute.get_scalars"(%715#0) : (!cute.int_tuple<"?">) -> i32
      %717 = "cute.get_scalars"(%715#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %718 = "cute.get_iter"(%707) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %719 = "cute.deref_arith_tuple_iter"(%718) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %720:2 = "cute.get_leaves"(%719) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %721 = "cute.get_scalars"(%720#0) : (!cute.int_tuple<"?">) -> i32
      %722 = "cute.get_scalars"(%720#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %723 = "cute.make_coord"(%720#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %724 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %725 = "cute.elem_less"(%723, %724) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %726 = "arith.extui"(%725) : (i1) -> i8
      %727 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%519, %727, %726) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %728 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %729 = "cute.get_shape"(%728) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %730:3 = "cute.get_leaves"(%729) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %731 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %732 = "cute.get_layout"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">
      %733 = "cute.crd2idx"(%731, %732) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %734 = "cute.get_iter"(%498) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %735 = "cute.add_offset"(%734, %733) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %736 = "cute.make_view"(%735) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %737 = "cute.get_iter"(%736) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %738 = "cute.deref_arith_tuple_iter"(%737) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %739:2 = "cute.get_leaves"(%738) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %740 = "cute.get_scalars"(%739#0) : (!cute.int_tuple<"?">) -> i32
      %741 = "cute.get_scalars"(%739#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %742 = "cute.get_iter"(%736) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %743 = "cute.deref_arith_tuple_iter"(%742) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %744:2 = "cute.get_leaves"(%743) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %745 = "cute.get_scalars"(%744#0) : (!cute.int_tuple<"?">) -> i32
      %746 = "cute.get_scalars"(%744#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %747 = "cute.get_iter"(%736) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %748 = "cute.deref_arith_tuple_iter"(%747) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %749:2 = "cute.get_leaves"(%748) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %750 = "cute.get_scalars"(%749#0) : (!cute.int_tuple<"?">) -> i32
      %751 = "cute.get_scalars"(%749#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %752 = "cute.make_coord"(%749#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %753 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %754 = "cute.elem_less"(%752, %753) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %755 = "arith.extui"(%754) : (i1) -> i8
      %756 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%519, %756, %755) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %757 = "cute.get_layout"(%213) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %758 = "cute.get_shape"(%757) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %759:4 = "cute.get_leaves"(%758) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %760 = "cute.get_layout"(%217) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %761 = "cute.get_shape"(%760) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %762:4 = "cute.get_leaves"(%761) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %763 = "cute.get_layout"(%213) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %764 = "cute.make_shape"() : () -> !cute.shape<"1">
      %765 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %766 = "cute.append_to_rank"(%763, %765) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %767 = "cute.make_view"(%214, %766) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
      %768 = "cute.get_iter"(%767) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %769 = "cute.get_layout"(%767) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %770 = "cute.get_shape"(%769) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %771:4 = "cute.get_leaves"(%770) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %772 = "cute.get_layout"(%767) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %773 = "cute.get_shape"(%772) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %774:4 = "cute.get_leaves"(%773) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %775 = "cute.get_iter"(%767) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %776 = "cute.make_view"(%775) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
      %777 = "cute.get_iter"(%776) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %778 = "cute.get_iter"(%776) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %779 = "cute.get_layout"(%217) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %780 = "cute.make_shape"() : () -> !cute.shape<"1">
      %781 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %782 = "cute.append_to_rank"(%779, %781) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %783 = "cute.make_view"(%219, %782) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %784 = "cute.get_iter"(%783) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %785 = "cute.get_layout"(%783) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %786 = "cute.get_shape"(%785) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %787:4 = "cute.get_leaves"(%786) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %788 = "cute.get_layout"(%783) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %789 = "cute.get_shape"(%788) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %790:4 = "cute.get_leaves"(%789) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %791 = "cute.get_iter"(%783) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %792 = "cute.make_view"(%791) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
      %793 = "cute.get_iter"(%792) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %794 = "cute.get_iter"(%792) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %795 = "cute.get_layout"(%519) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %796 = "cute.make_shape"() : () -> !cute.shape<"1">
      %797 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
      %798 = "cute.append_to_rank"(%795, %797) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %799 = "cute.make_view"(%521, %798) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %800 = "cute.get_iter"(%799) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %801 = "cute.get_layout"(%799) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %802 = "cute.get_shape"(%801) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %803:3 = "cute.get_leaves"(%802) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %804 = "cute.get_layout"(%799) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %805 = "cute.get_shape"(%804) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %806:3 = "cute.get_leaves"(%805) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %807 = "cute.get_iter"(%799) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %808 = "cute.make_view"(%807) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %809 = "cute.get_iter"(%808) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %810 = "cute.get_iter"(%808) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %811 = "cute.get_layout"(%776) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %812 = "cute.get_shape"(%811) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %813:4 = "cute.get_leaves"(%812) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %814 = "cute.get_layout"(%792) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %815 = "cute.get_shape"(%814) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %816:4 = "cute.get_leaves"(%815) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %817 = "cute.get_layout"(%776) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %818 = "cute.size"(%817) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
      %819 = "cute.get_leaves"(%818) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %820 = "cute.get_layout"(%792) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %821 = "cute.size"(%820) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
      %822 = "cute.get_leaves"(%821) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %823 = "cute.static"() : () -> !cute.layout<"1:0">
      %824 = "cute.get_iter"(%776) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %825 = "cute.get_iter"(%792) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %826 = "cute.get_layout"(%776) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %827 = "cute.get_layout"(%792) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %828 = "cute.append_to_rank"(%826, %823) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %829 = "cute.append_to_rank"(%827, %823) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %830 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
      %831 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
      %832 = "cute.get_iter"(%808) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %833 = "cute.get_layout"(%808) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
      %834 = "cute.append_to_rank"(%833, %823) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
      %835 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %836 = "cute.size"(%830) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
      %837 = "cute.get_scalars"(%836) : (!cute.int_tuple<"1">) -> i32
      %838 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %839 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%838, %837, %839) ({
      ^bb0(%arg13: i32):
        %1191 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"(_,?)">
        %1192 = "cute.slice"(%830, %1191) : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,512))">
        %1193 = "cute.crd2idx"(%1191, %830) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
        %1194 = "cute.add_offset"(%824, %1193) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %1195 = "cute.make_view"(%1194, %1192) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
        %1196 = "cute.slice"(%831, %1191) : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,8))">
        %1197 = "cute.crd2idx"(%1191, %831) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
        %1198 = "cute.add_offset"(%825, %1197) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %1199 = "cute.make_view"(%1198, %1196) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
        %1200 = "cute.slice"(%835, %1191) : (!cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
        %1201 = "cute.crd2idx"(%1191, %835) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %1202 = "cute.add_offset"(%832, %1201) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %1203 = "cute.make_view"(%1202, %1200) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
        "cute.copy_atom_call"(%178, %1195, %1199, %1203) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_7, !memref_rmem_bf16_2, !memref_rmem_i8_2) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %840 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %841 = "cute.get_shape"(%840) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %842:4 = "cute.get_leaves"(%841) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %843 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %844 = "cute.get_shape"(%843) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %845:4 = "cute.get_leaves"(%844) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %846 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %847 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %848 = "cute.right_inverse"(%847) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %849 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,8):(1,512)">
      %850 = "cute.coalesce"(%849) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %851 = "cute.get_shape"(%850) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %852:2 = "cute.get_leaves"(%851) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %853 = "cute.get_stride"(%850) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %854:2 = "cute.get_leaves"(%853) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %855 = "cute.get_shape"(%850) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %856:2 = "cute.get_leaves"(%855) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %857 = "cute.get_shape"(%850) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %858:2 = "cute.get_leaves"(%857) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %859 = "cute.get"(%850) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %860 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %861 = "cute.size"(%860) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %862 = "cute.get_leaves"(%861) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %863 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %864 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %865 = "cute.get_iter"(%190) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %866 = "cute.make_view"(%865) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %867 = "cute.get_iter"(%866) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %868 = "cute.get_iter"(%866) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %869 = "cute.get_iter"(%204) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %870 = "cute.make_view"(%869) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %871 = "cute.get_iter"(%870) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %872 = "cute.get_iter"(%870) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %873 = "cute.make_shape"() : () -> !cute.shape<"8">
      %874 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %875 = "cute.get_iter"(%866) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %876 = "cute.make_view"(%875) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %877 = "cute.get_iter"(%876) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %878 = "cute.get_iter"(%876) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %879 = "cute.make_shape"() : () -> !cute.shape<"8">
      %880 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %881 = "cute.get_iter"(%870) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %882 = "cute.make_view"(%881) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %883 = "cute.get_iter"(%882) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %884 = "cute.get_iter"(%882) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %885 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %886 = "cute.static"() : () -> !cute.layout<"1:0">
      %887 = "cute.get_iter"(%876) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %888 = "cute.get_iter"(%882) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %889 = "cute.get_layout"(%876) : (!memref_smem_bf16_4) -> !cute.layout<"(8,8):(1,512)">
      %890 = "cute.get_layout"(%882) : (!memref_rmem_bf16_3) -> !cute.layout<"(8,8):(1,8)">
      %891 = "cute.append_to_rank"(%889, %886) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,512)">
      %892 = "cute.append_to_rank"(%890, %886) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,8)">
      %893 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(512))">
      %894 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(8))">
      %895 = "cute.size"(%893) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %896 = "cute.get_scalars"(%895) : (!cute.int_tuple<"8">) -> i32
      %897 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %898 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%897, %896, %898) ({
      ^bb0(%arg12: i32):
        %1182 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"(_,?)">
        %1183 = "cute.slice"(%893, %1182) : (!cute.layout<"(8,(8)):(1,(512))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
        %1184 = "cute.crd2idx"(%1182, %893) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %1185 = "cute.add_offset"(%887, %1184) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %1186 = "cute.make_view"(%1185, %1183) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %1187 = "cute.slice"(%894, %1182) : (!cute.layout<"(8,(8)):(1,(8))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
        %1188 = "cute.crd2idx"(%1182, %894) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %1189 = "cute.add_offset"(%888, %1188) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1190 = "cute.make_view"(%1189, %1187) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        "cute.copy_atom_call"(%885, %1186, %1190) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_5, !memref_rmem_bf16_4) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %899 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %900 = "cute.get_shape"(%899) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %901:4 = "cute.get_leaves"(%900) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %902 = "cute.memref.load_vec"(%204) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %903 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %904 = "cute.get_shape"(%903) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %905:4 = "cute.get_leaves"(%904) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %906 = "arith.extf"(%902) : (vector<64xbf16>) -> vector<64xf32>
      %907 = "arith.mulf"(%906, %906) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %908 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %909 = "vector.reduction"(%907, %908) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %910 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %911 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %912 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %913 = "nvvm.shfl.sync"(%910, %909, %911, %912) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %914 = "arith.addf"(%913, %909) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %915 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %916 = "nvvm.shfl.sync"(%910, %914, %915, %912) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %917 = "arith.addf"(%914, %916) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %918 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %919 = "nvvm.shfl.sync"(%910, %917, %918, %912) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %920 = "arith.addf"(%917, %919) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %921 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %922 = "nvvm.shfl.sync"(%910, %920, %921, %912) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %923 = "arith.addf"(%920, %922) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %924 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %925 = "nvvm.shfl.sync"(%910, %923, %924, %912) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %926 = "arith.addf"(%923, %925) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %927 = "nvvm.read.ptx.sreg.laneid"() : () -> i32
      %928 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %929 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %930 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %931 = "nvvm.read.ptx.sreg.ntid.x"() : () -> i32
      %932 = "nvvm.read.ptx.sreg.ntid.y"() : () -> i32
      %933 = "arith.muli"(%929, %931) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %934 = "arith.addi"(%928, %933) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %935 = "arith.muli"(%930, %931) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %936 = "arith.muli"(%935, %932) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %937 = "arith.addi"(%934, %936) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %938 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %939 = "arith.floordivsi"(%937, %938) : (i32, i32) -> i32
      %940 = "cute.get_layout"(%95) : (!memref_smem_f32_) -> !cute.layout<"(2,2):(1,2)">
      %941 = "cute.get_shape"(%940) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %942:2 = "cute.get_leaves"(%941) : (!cute.shape<"(2,2)">) -> (!cute.shape<"2">, !cute.shape<"2">)
      %943 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
      %944 = "cute.size"(%943) <{mode = array<i32>}> : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %945 = "cute.get_leaves"(%944) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %946 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %947 = "arith.floordivsi"(%939, %946) : (i32, i32) -> i32
      %948 = "arith.remsi"(%939, %946) : (i32, i32) -> i32
      %949 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %950 = "arith.cmpi"(%927, %949) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %951 = "scf.if"(%950) ({
        %1180 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        %1181 = "cute.make_coord"(%947, %948) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%95, %1181, %926) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"(%95) : (!memref_smem_f32_) -> ()
      }, {
        %1179 = "cute.get_iter"(%95) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        "scf.yield"(%95) : (!memref_smem_f32_) -> ()
      }) : (i1) -> !memref_smem_f32_
      %952 = "cute.get_iter"(%951) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %953 = "cute.get_iter"(%951) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %954 = "cute.get_iter"(%951) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %955 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%955) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %956 = "arith.cmpi"(%927, %946) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %957 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %958 = "scf.if"(%956) ({
        %1177 = "cute.make_coord"(%947, %927) : (i32, i32) -> !cute.coord<"(?,?)">
        %1178 = "cute.memref.load"(%951, %1177) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%1178) : (f32) -> ()
      }, {
        "scf.yield"(%957) : (f32) -> ()
      }) : (i1) -> f32
      %959 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %960 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %961 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %962 = "nvvm.shfl.sync"(%959, %958, %960, %961) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %963 = "arith.addf"(%958, %962) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %964 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %965 = "nvvm.shfl.sync"(%959, %963, %964, %961) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %966 = "arith.addf"(%963, %965) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %967 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %968 = "nvvm.shfl.sync"(%959, %966, %967, %961) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %969 = "arith.addf"(%966, %968) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %970 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %971 = "nvvm.shfl.sync"(%959, %969, %970, %961) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %972 = "arith.addf"(%969, %971) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %973 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %974 = "nvvm.shfl.sync"(%959, %972, %973, %961) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %975 = "arith.addf"(%972, %974) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %976 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %977 = "arith.divf"(%975, %976) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %978 = "arith.addf"(%977, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %979 = "math.rsqrt"(%978) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      %980 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%980) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %981 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %982 = "cute.get_shape"(%981) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %983:4 = "cute.get_leaves"(%982) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %984 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %985 = "cute.get_shape"(%984) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %986:4 = "cute.get_leaves"(%985) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %987 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %988 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %989 = "cute.right_inverse"(%988) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %990 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,8):(1,512)">
      %991 = "cute.coalesce"(%990) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %992 = "cute.get_shape"(%991) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %993:2 = "cute.get_leaves"(%992) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %994 = "cute.get_stride"(%991) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %995:2 = "cute.get_leaves"(%994) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %996 = "cute.get_shape"(%991) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %997:2 = "cute.get_leaves"(%996) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %998 = "cute.get_shape"(%991) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %999:2 = "cute.get_leaves"(%998) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %1000 = "cute.get"(%991) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %1001 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1002 = "cute.size"(%1001) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %1003 = "cute.get_leaves"(%1002) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %1004 = "cute.get_layout"(%190) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %1005 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1006 = "cute.get_iter"(%190) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %1007 = "cute.make_view"(%1006) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1008 = "cute.get_iter"(%1007) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1009 = "cute.get_iter"(%1007) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1010 = "cute.get_iter"(%204) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %1011 = "cute.make_view"(%1010) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1012 = "cute.get_iter"(%1011) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1013 = "cute.get_iter"(%1011) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1014 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1015 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1016 = "cute.get_iter"(%1007) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1017 = "cute.make_view"(%1016) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %1018 = "cute.get_iter"(%1017) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1019 = "cute.get_iter"(%1017) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1020 = "cute.make_shape"() : () -> !cute.shape<"8">
      %1021 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
      %1022 = "cute.get_iter"(%1011) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1023 = "cute.make_view"(%1022) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_3
      %1024 = "cute.get_iter"(%1023) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1025 = "cute.get_iter"(%1023) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1026 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %1027 = "cute.static"() : () -> !cute.layout<"1:0">
      %1028 = "cute.get_iter"(%1017) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
      %1029 = "cute.get_iter"(%1023) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<32>>
      %1030 = "cute.get_layout"(%1017) : (!memref_smem_bf16_4) -> !cute.layout<"(8,8):(1,512)">
      %1031 = "cute.get_layout"(%1023) : (!memref_rmem_bf16_3) -> !cute.layout<"(8,8):(1,8)">
      %1032 = "cute.append_to_rank"(%1030, %1027) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,512)">
      %1033 = "cute.append_to_rank"(%1031, %1027) <{rank = 2 : si32}> : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">) -> !cute.layout<"(8,8):(1,8)">
      %1034 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(512))">
      %1035 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,(8)):(1,(8))">
      %1036 = "cute.size"(%1034) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %1037 = "cute.get_scalars"(%1036) : (!cute.int_tuple<"8">) -> i32
      %1038 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1039 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%1038, %1037, %1039) ({
      ^bb0(%arg11: i32):
        %1168 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %1169 = "cute.slice"(%1034, %1168) : (!cute.layout<"(8,(8)):(1,(512))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
        %1170 = "cute.crd2idx"(%1168, %1034) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %1171 = "cute.add_offset"(%1028, %1170) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %1172 = "cute.make_view"(%1171, %1169) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_smem_bf16_5
        %1173 = "cute.slice"(%1035, %1168) : (!cute.layout<"(8,(8)):(1,(8))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
        %1174 = "cute.crd2idx"(%1168, %1035) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %1175 = "cute.add_offset"(%1029, %1174) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1176 = "cute.make_view"(%1175, %1173) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(8):(1)">) -> !memref_rmem_bf16_4
        "cute.copy_atom_call"(%1026, %1172, %1176) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_5, !memref_rmem_bf16_4) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %1040 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1041 = "cute.get_shape"(%1040) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1042:4 = "cute.get_leaves"(%1041) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1043 = "cute.memref.load_vec"(%204) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %1044 = "cute.get_layout"(%204) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1045 = "cute.get_shape"(%1044) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1046:4 = "cute.get_leaves"(%1045) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1047 = "arith.extf"(%1043) : (vector<64xbf16>) -> vector<64xf32>
      %1048 = "vector.broadcast"(%979) : (f32) -> vector<64xf32>
      %1049 = "arith.mulf"(%1047, %1048) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %1050 = "cute.get_layout"(%220) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1051 = "cute.get_shape"(%1050) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1052:4 = "cute.get_leaves"(%1051) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1053 = "cute.memref.load_vec"(%220) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %1054 = "cute.get_layout"(%220) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1055 = "cute.get_shape"(%1054) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1056:4 = "cute.get_leaves"(%1055) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1057 = "arith.extf"(%1053) : (vector<64xbf16>) -> vector<64xf32>
      %1058 = "arith.mulf"(%1049, %1057) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %1059 = "arith.truncf"(%1058) : (vector<64xf32>) -> vector<64xbf16>
      %1060 = "cute.get_layout"(%209) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1061 = "cute.get_shape"(%1060) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1062:4 = "cute.get_leaves"(%1061) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1063 = "cute.get_layout"(%209) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %1064 = "cute.get_shape"(%1063) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %1065:4 = "cute.get_leaves"(%1064) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %1066 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %1067 = "cute.size"(%1066) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %1068 = "cute.get_leaves"(%1067) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      %1069 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %1070 = "cute.size"(%1069) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %1071 = "cute.get_leaves"(%1070) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      "cute.memref.store_vec"(%1059, %209) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%496) ({
        %1072 = "cute.get_layout"(%209) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1073 = "cute.get_shape"(%1072) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1074:4 = "cute.get_leaves"(%1073) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1075 = "cute.get_layout"(%193) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1076 = "cute.get_shape"(%1075) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1077:4 = "cute.get_leaves"(%1076) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1078 = "cute.get_layout"(%209) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1079 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1080 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1081 = "cute.append_to_rank"(%1078, %1080) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1082 = "cute.make_view"(%211, %1081) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
        %1083 = "cute.get_iter"(%1082) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %1084 = "cute.get_layout"(%1082) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1085 = "cute.get_shape"(%1084) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1086:4 = "cute.get_leaves"(%1085) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1087 = "cute.get_layout"(%1082) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %1088 = "cute.get_shape"(%1087) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1089:4 = "cute.get_leaves"(%1088) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1090 = "cute.get_iter"(%1082) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %1091 = "cute.make_view"(%1090) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_1
        %1092 = "cute.get_iter"(%1091) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1093 = "cute.get_iter"(%1091) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1094 = "cute.get_layout"(%193) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1095 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1096 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1097 = "cute.append_to_rank"(%1094, %1096) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1098 = "cute.make_view"(%194, %1097) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %1099 = "cute.get_iter"(%1098) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1100 = "cute.get_layout"(%1098) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1101 = "cute.get_shape"(%1100) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1102:4 = "cute.get_leaves"(%1101) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1103 = "cute.get_layout"(%1098) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %1104 = "cute.get_shape"(%1103) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %1105:4 = "cute.get_leaves"(%1104) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1106 = "cute.get_iter"(%1098) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1107 = "cute.make_view"(%1106) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_6
        %1108 = "cute.get_iter"(%1107) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1109 = "cute.get_iter"(%1107) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1110 = "cute.get_layout"(%237) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1111 = "cute.make_shape"() : () -> !cute.shape<"1">
        %1112 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %1113 = "cute.append_to_rank"(%1110, %1112) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1114 = "cute.make_view"(%239, %1113) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1115 = "cute.get_iter"(%1114) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1116 = "cute.get_layout"(%1114) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1117 = "cute.get_shape"(%1116) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1118:3 = "cute.get_leaves"(%1117) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1119 = "cute.get_layout"(%1114) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1120 = "cute.get_shape"(%1119) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1121:3 = "cute.get_leaves"(%1120) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1122 = "cute.get_iter"(%1114) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1123 = "cute.make_view"(%1122) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1124 = "cute.get_iter"(%1123) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1125 = "cute.get_iter"(%1123) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1126 = "cute.get_layout"(%1091) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1127 = "cute.get_shape"(%1126) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1128:4 = "cute.get_leaves"(%1127) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1129 = "cute.get_layout"(%1107) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1130 = "cute.get_shape"(%1129) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1131:4 = "cute.get_leaves"(%1130) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1132 = "cute.get_layout"(%1091) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1133 = "cute.size"(%1132) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
        %1134 = "cute.get_leaves"(%1133) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1135 = "cute.get_layout"(%1107) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1136 = "cute.size"(%1135) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %1137 = "cute.get_leaves"(%1136) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1138 = "cute.static"() : () -> !cute.layout<"1:0">
        %1139 = "cute.get_iter"(%1091) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %1140 = "cute.get_iter"(%1107) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %1141 = "cute.get_layout"(%1091) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1142 = "cute.get_layout"(%1107) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1143 = "cute.append_to_rank"(%1141, %1138) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %1144 = "cute.append_to_rank"(%1142, %1138) <{rank = 2 : si32}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1145 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
        %1146 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %1147 = "cute.get_iter"(%1123) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1148 = "cute.get_layout"(%1123) : (!memref_rmem_i8_1) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1149 = "cute.append_to_rank"(%1148, %1138) <{rank = 2 : si32}> : (!cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1,1)):(1,(0,1))">
        %1150 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %1151 = "cute.size"(%1145) <{mode = array<i32: 1>}> : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"1">
        %1152 = "cute.get_scalars"(%1151) : (!cute.int_tuple<"1">) -> i32
        %1153 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1154 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1153, %1152, %1154) ({
        ^bb0(%arg10: i32):
          %1155 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
          %1156 = "cute.slice"(%1145, %1155) : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,8))">
          %1157 = "cute.crd2idx"(%1155, %1145) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
          %1158 = "cute.add_offset"(%1139, %1157) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %1159 = "cute.make_view"(%1158, %1156) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8)):((1,8))">) -> !memref_rmem_bf16_2
          %1160 = "cute.slice"(%1146, %1155) : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"((8,8)):((1,512))">
          %1161 = "cute.crd2idx"(%1155, %1146) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %1162 = "cute.add_offset"(%1140, %1161) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %1163 = "cute.make_view"(%1162, %1160) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8)):((1,512))">) -> !memref_gmem_bf16_7
          %1164 = "cute.slice"(%1150, %1155) : (!cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
          %1165 = "cute.crd2idx"(%1155, %1150) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %1166 = "cute.add_offset"(%1147, %1165) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1167 = "cute.make_view"(%1166, %1164) : (!cute.ptr<i8, rmem>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_2
          "cute.copy_atom_call"(%179, %1159, %1163, %1167) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_2, !memref_gmem_bf16_7, !memref_rmem_i8_2) -> ()
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
