!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(4096,1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "((2),4096):((0),1)">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(0,1)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((8,8),(1,1)):((1,8),(0,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "(8,8):(1,8)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8,(1,1)):(1,(0,1))">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "(2,4096):(4096,1)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "(8,8):(1,512)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> (), sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0"}> ({
    ^bb0(%arg6: !memref_gmem_bf16_, %arg7: !memref_gmem_bf16_1, %arg8: !memref_gmem_bf16_, %arg9: f32):
      %36 = "cute.static"() : () -> !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
      %37 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %38 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %39 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %40 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %41 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %42 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %43 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %44 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %45 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %46 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %47 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %48 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %49 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %50 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %51 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %52 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %53 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %54 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %55 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %56 = "cute.get_shape"(%55) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %57:2 = "cute.get_leaves"(%56) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %58 = "cute.to_int_tuple"(%57#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %59 = "cute.get_scalars"(%58) : (!cute.int_tuple<"?">) -> i32
      %60 = "cute.get_shape"(%36) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %61:4 = "cute.get_leaves"(%60) : (!cute.shape<"((64,2),(8,8))">) -> (!cute.shape<"64">, !cute.shape<"2">, !cute.shape<"8">, !cute.shape<"8">)
      %62 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %63 = "cute.make_shape"() : () -> !cute.shape<"(2,4096)">
      %64 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
      %65 = "cute.make_ordered_layout"(%63, %64) : (!cute.shape<"(2,4096)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(2,4096):(4096,1)">
      %66 = "cute.make_coord"() : () -> !cute.coord<"0">
      %67 = "cute.crd2idx"(%66, %65) : (!cute.coord<"0">, !cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"0">
      %68 = "cute.get_leaves"(%67) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %69 = "cute.cosize"(%65) <{mode = array<i32>}> : (!cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"8192">
      %70 = "cute.get_leaves"(%69) : (!cute.int_tuple<"8192">) -> !cute.int_tuple<"8192">
      %71 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16384">
      %72 = "cute.add_offset"(%62, %71) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %73 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %74 = "arith.constant"() <{value = 16384 : i32}> : () -> i32
      %75 = "arith.cmpi"(%73, %74) <{predicate = 5 : i64}> : (i32, i32) -> i1
      "cf.assert"(%75) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16384 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %76 = "cute.recast_iter"(%62) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %77 = "cute.make_view"(%76, %65) : (!cute.ptr<bf16, smem, align<1024>>, !cute.layout<"(2,4096):(4096,1)">) -> !memref_smem_bf16_
      %78 = "cute.get_iter"(%77) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %79 = "cute.make_shape"() : () -> !cute.shape<"(2,2)">
      %80 = "cute.make_layout"(%79) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(2,2)">) -> !cute.layout<"(2,2):(1,2)">
      %81 = "cute.make_coord"() : () -> !cute.coord<"0">
      %82 = "cute.crd2idx"(%81, %80) : (!cute.coord<"0">, !cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"0">
      %83 = "cute.get_leaves"(%82) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %84 = "cute.cosize"(%80) <{mode = array<i32>}> : (!cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"4">
      %85 = "cute.get_leaves"(%84) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %86 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
      %87 = "cute.add_offset"(%72, %86) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i8, smem, align<16>>
      %88 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %89 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
      %90 = "arith.cmpi"(%88, %89) <{predicate = 5 : i64}> : (i32, i32) -> i1
      "cf.assert"(%90) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16400 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %91 = "cute.recast_iter"(%72) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %92 = "cute.make_view"(%91, %80) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %93 = "cute.get_iter"(%92) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %94 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %95 = "cute.get_shape"(%94) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %96:2 = "cute.get_leaves"(%95) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %97 = "cute.to_int_tuple"(%96#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %98 = "cute.get_scalars"(%97) : (!cute.int_tuple<"?">) -> i32
      %99 = "cute.make_shape"(%97) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %100 = "cute.make_identity_tensor"(%99) : (!cute.shape<"(?,4096)">) -> !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %101 = "cute.get_iter"(%100) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %102 = "cute.deref_arith_tuple_iter"(%101) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %103:2 = "cute.get_leaves"(%102) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %104 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %105 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"(?,0)">
      %106 = "cute.local_tile"(%arg6, %104, %105) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %107 = "cute.get_iter"(%106) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %108 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %109 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"(?,0)">
      %110 = "cute.local_tile"(%arg8, %108, %109) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %111 = "cute.get_iter"(%110) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %112 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %113 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"(?,0)">
      %114 = "cute.local_tile"(%100, %112, %113) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %115 = "cute.get_iter"(%114) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %116 = "cute.deref_arith_tuple_iter"(%115) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %117:2 = "cute.get_leaves"(%116) : (!cute.int_tuple<"(?{div=2},0)">) -> (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"0">)
      %118 = "cute.get_scalars"(%117#0) : (!cute.int_tuple<"?{div=2}">) -> i32
      %119 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %120 = "cute.make_shape"() : () -> !cute.shape<"(2)">
      %121 = "cute.make_stride"() : () -> !cute.stride<"(0)">
      %122 = "cute.make_layout"(%120, %121) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(0)">) -> !cute.layout<"(2):(0)">
      %123 = "cute.get_shape"(%119) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %124 = "cute.get_leaves"(%123) : (!cute.shape<"(4096)">) -> !cute.shape<"4096">
      %125 = "cute.prepend_to_rank"(%119, %122) <{rank = 2 : si32}> : (!cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">) -> !cute.layout<"((2),4096):((0),1)">
      %126 = "cute.make_view"(%41, %125) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((2),4096):((0),1)">) -> !memref_gmem_bf16_3
      %127 = "cute.get_iter"(%126) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %128 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %129 = "cute.make_coord"() : () -> !cute.coord<"(0,0)">
      %130 = "cute.local_tile"(%126, %128, %129) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_3, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(0,0)">) -> !memref_gmem_bf16_4
      %131 = "cute.get_iter"(%130) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %132 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %133 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %134 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %135 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %136 = "cute.make_tiled_copy"(%132) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %137 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %138 = "cute.make_tiled_copy"(%133) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %139 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %140 = "cute.make_tiled_copy"(%134) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %141 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %142 = "cute.tiled.copy.partition_S"(%136, %106, %141) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %143 = "cute.get_iter"(%142) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %144 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %145 = "cute.tiled.copy.partition_D"(%136, %77, %144) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %146 = "cute.get_iter"(%145) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %147 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %148 = "cute.tiled.copy.partition_D"(%140, %110, %147) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %149 = "cute.get_iter"(%148) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %150 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %151 = "cute.tiled.copy.partition_S"(%136, %114, %150) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %152 = "cute.get_iter"(%151) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %153 = "cute.deref_arith_tuple_iter"(%152) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %154:2 = "cute.get_leaves"(%153) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %155 = "cute.get_scalars"(%154#0) : (!cute.int_tuple<"?">) -> i32
      %156 = "cute.get_scalars"(%154#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %157 = "cute.get_layout"(%142) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %158 = "cute.make_layout_like"(%157) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %159 = "cute.memref.alloca"(%158) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %160 = "cute.get_iter"(%159) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %161 = "cute.get_iter"(%159) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %162 = "cute.get_layout"(%148) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %163 = "cute.make_layout_like"(%162) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %164 = "cute.memref.alloca"(%163) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %165 = "cute.get_iter"(%164) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %166 = "cute.get_iter"(%164) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %167 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %168 = "cute.tiled.copy.partition_S"(%138, %130, %167) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %169 = "cute.get_iter"(%168) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %170 = "cute.get_layout"(%168) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %171 = "cute.make_layout_like"(%170) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %172 = "cute.memref.alloca"(%171) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %173 = "cute.get_iter"(%172) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %174 = "cute.get_iter"(%172) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %175 = "cute.tiled.copy.retile"(%136, %172) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %176 = "cute.get_iter"(%175) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %177 = "cute.size"(%151) <{mode = array<i32: 0, 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %178 = "cute.get_leaves"(%177) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %179 = "cute.size"(%151) <{mode = array<i32: 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %180 = "cute.get_leaves"(%179) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %181 = "cute.size"(%151) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %182 = "cute.get_leaves"(%181) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %183 = "cute.size"(%151) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %184 = "cute.get_leaves"(%183) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %185 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %186 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %187 = "cute.make_layout"(%185, %186) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(8,1,1)">, !cute.stride<"(1,0,1)">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %188 = "cute.memref.alloca"(%187) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %189 = "cute.get_iter"(%188) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %190 = "cute.get_iter"(%188) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %191 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %192 = "cute.get_shape"(%191) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %193:3 = "cute.get_leaves"(%192) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %194 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %195 = "cute.get_shape"(%194) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %196:3 = "cute.get_leaves"(%195) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %197 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %198 = "cute.slice"(%151, %197) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %199 = "cute.get_iter"(%198) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %200 = "cute.deref_arith_tuple_iter"(%199) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %201:2 = "cute.get_leaves"(%200) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %202 = "cute.get_scalars"(%201#0) : (!cute.int_tuple<"?">) -> i32
      %203 = "cute.get_scalars"(%201#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %204 = "cute.get_iter"(%198) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %205 = "cute.deref_arith_tuple_iter"(%204) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %206:2 = "cute.get_leaves"(%205) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %207 = "cute.get_scalars"(%206#0) : (!cute.int_tuple<"?">) -> i32
      %208 = "cute.get_scalars"(%206#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %209 = "cute.get_iter"(%198) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %210 = "cute.deref_arith_tuple_iter"(%209) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %211:2 = "cute.get_leaves"(%210) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %212 = "cute.get_scalars"(%211#0) : (!cute.int_tuple<"?">) -> i32
      %213 = "cute.get_scalars"(%211#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %214 = "cute.make_coord"(%211#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %215 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %216 = "cute.elem_less"(%214, %215) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %217 = "arith.extui"(%216) : (i1) -> i8
      %218 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%188, %218, %217) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %219 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %220 = "cute.get_shape"(%219) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %221:3 = "cute.get_leaves"(%220) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %222 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %223 = "cute.slice"(%151, %222) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %224 = "cute.get_iter"(%223) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %225 = "cute.deref_arith_tuple_iter"(%224) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %226:2 = "cute.get_leaves"(%225) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %227 = "cute.get_scalars"(%226#0) : (!cute.int_tuple<"?">) -> i32
      %228 = "cute.get_scalars"(%226#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %229 = "cute.get_iter"(%223) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %230 = "cute.deref_arith_tuple_iter"(%229) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %231:2 = "cute.get_leaves"(%230) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %232 = "cute.get_scalars"(%231#0) : (!cute.int_tuple<"?">) -> i32
      %233 = "cute.get_scalars"(%231#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %234 = "cute.get_iter"(%223) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %235 = "cute.deref_arith_tuple_iter"(%234) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %236:2 = "cute.get_leaves"(%235) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %237 = "cute.get_scalars"(%236#0) : (!cute.int_tuple<"?">) -> i32
      %238 = "cute.get_scalars"(%236#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %239 = "cute.make_coord"(%236#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %240 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %241 = "cute.elem_less"(%239, %240) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %242 = "arith.extui"(%241) : (i1) -> i8
      %243 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%188, %243, %242) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %244 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %245 = "cute.get_shape"(%244) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %246:3 = "cute.get_leaves"(%245) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %247 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %248 = "cute.slice"(%151, %247) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %249 = "cute.get_iter"(%248) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %250 = "cute.deref_arith_tuple_iter"(%249) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %251:2 = "cute.get_leaves"(%250) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %252 = "cute.get_scalars"(%251#0) : (!cute.int_tuple<"?">) -> i32
      %253 = "cute.get_scalars"(%251#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %254 = "cute.get_iter"(%248) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %255 = "cute.deref_arith_tuple_iter"(%254) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %256:2 = "cute.get_leaves"(%255) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %257 = "cute.get_scalars"(%256#0) : (!cute.int_tuple<"?">) -> i32
      %258 = "cute.get_scalars"(%256#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %259 = "cute.get_iter"(%248) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %260 = "cute.deref_arith_tuple_iter"(%259) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %261:2 = "cute.get_leaves"(%260) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %262 = "cute.get_scalars"(%261#0) : (!cute.int_tuple<"?">) -> i32
      %263 = "cute.get_scalars"(%261#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %264 = "cute.make_coord"(%261#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %265 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %266 = "cute.elem_less"(%264, %265) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %267 = "arith.extui"(%266) : (i1) -> i8
      %268 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%188, %268, %267) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %269 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %270 = "cute.get_shape"(%269) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %271:3 = "cute.get_leaves"(%270) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %272 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %273 = "cute.slice"(%151, %272) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %274 = "cute.get_iter"(%273) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %275 = "cute.deref_arith_tuple_iter"(%274) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %276:2 = "cute.get_leaves"(%275) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %277 = "cute.get_scalars"(%276#0) : (!cute.int_tuple<"?">) -> i32
      %278 = "cute.get_scalars"(%276#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %279 = "cute.get_iter"(%273) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %280 = "cute.deref_arith_tuple_iter"(%279) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %281:2 = "cute.get_leaves"(%280) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %282 = "cute.get_scalars"(%281#0) : (!cute.int_tuple<"?">) -> i32
      %283 = "cute.get_scalars"(%281#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %284 = "cute.get_iter"(%273) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %285 = "cute.deref_arith_tuple_iter"(%284) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %286:2 = "cute.get_leaves"(%285) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %287 = "cute.get_scalars"(%286#0) : (!cute.int_tuple<"?">) -> i32
      %288 = "cute.get_scalars"(%286#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %289 = "cute.make_coord"(%286#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %290 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %291 = "cute.elem_less"(%289, %290) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %292 = "arith.extui"(%291) : (i1) -> i8
      %293 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%188, %293, %292) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %294 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %295 = "cute.get_shape"(%294) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %296:3 = "cute.get_leaves"(%295) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %297 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %298 = "cute.slice"(%151, %297) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %299 = "cute.get_iter"(%298) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %300 = "cute.deref_arith_tuple_iter"(%299) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %301:2 = "cute.get_leaves"(%300) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %302 = "cute.get_scalars"(%301#0) : (!cute.int_tuple<"?">) -> i32
      %303 = "cute.get_scalars"(%301#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %304 = "cute.get_iter"(%298) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %305 = "cute.deref_arith_tuple_iter"(%304) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %306:2 = "cute.get_leaves"(%305) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %307 = "cute.get_scalars"(%306#0) : (!cute.int_tuple<"?">) -> i32
      %308 = "cute.get_scalars"(%306#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %309 = "cute.get_iter"(%298) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %310 = "cute.deref_arith_tuple_iter"(%309) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %311:2 = "cute.get_leaves"(%310) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %312 = "cute.get_scalars"(%311#0) : (!cute.int_tuple<"?">) -> i32
      %313 = "cute.get_scalars"(%311#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %314 = "cute.make_coord"(%311#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %315 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %316 = "cute.elem_less"(%314, %315) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %317 = "arith.extui"(%316) : (i1) -> i8
      %318 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%188, %318, %317) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %319 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %320 = "cute.get_shape"(%319) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %321:3 = "cute.get_leaves"(%320) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %322 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %323 = "cute.slice"(%151, %322) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %324 = "cute.get_iter"(%323) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %325 = "cute.deref_arith_tuple_iter"(%324) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %326:2 = "cute.get_leaves"(%325) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %327 = "cute.get_scalars"(%326#0) : (!cute.int_tuple<"?">) -> i32
      %328 = "cute.get_scalars"(%326#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %329 = "cute.get_iter"(%323) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %330 = "cute.deref_arith_tuple_iter"(%329) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %331:2 = "cute.get_leaves"(%330) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %332 = "cute.get_scalars"(%331#0) : (!cute.int_tuple<"?">) -> i32
      %333 = "cute.get_scalars"(%331#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %334 = "cute.get_iter"(%323) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %335 = "cute.deref_arith_tuple_iter"(%334) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %336:2 = "cute.get_leaves"(%335) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %337 = "cute.get_scalars"(%336#0) : (!cute.int_tuple<"?">) -> i32
      %338 = "cute.get_scalars"(%336#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %339 = "cute.make_coord"(%336#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %340 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %341 = "cute.elem_less"(%339, %340) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %342 = "arith.extui"(%341) : (i1) -> i8
      %343 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%188, %343, %342) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %344 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %345 = "cute.get_shape"(%344) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %346:3 = "cute.get_leaves"(%345) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %347 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %348 = "cute.slice"(%151, %347) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %349 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %350 = "cute.deref_arith_tuple_iter"(%349) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %351:2 = "cute.get_leaves"(%350) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %352 = "cute.get_scalars"(%351#0) : (!cute.int_tuple<"?">) -> i32
      %353 = "cute.get_scalars"(%351#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %354 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %355 = "cute.deref_arith_tuple_iter"(%354) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %356:2 = "cute.get_leaves"(%355) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %357 = "cute.get_scalars"(%356#0) : (!cute.int_tuple<"?">) -> i32
      %358 = "cute.get_scalars"(%356#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %359 = "cute.get_iter"(%348) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %360 = "cute.deref_arith_tuple_iter"(%359) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %361:2 = "cute.get_leaves"(%360) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %362 = "cute.get_scalars"(%361#0) : (!cute.int_tuple<"?">) -> i32
      %363 = "cute.get_scalars"(%361#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %364 = "cute.make_coord"(%361#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %365 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %366 = "cute.elem_less"(%364, %365) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %367 = "arith.extui"(%366) : (i1) -> i8
      %368 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%188, %368, %367) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %369 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %370 = "cute.get_shape"(%369) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %371:3 = "cute.get_leaves"(%370) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %372 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %373 = "cute.slice"(%151, %372) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %374 = "cute.get_iter"(%373) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %375 = "cute.deref_arith_tuple_iter"(%374) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %376:2 = "cute.get_leaves"(%375) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %377 = "cute.get_scalars"(%376#0) : (!cute.int_tuple<"?">) -> i32
      %378 = "cute.get_scalars"(%376#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %379 = "cute.get_iter"(%373) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %380 = "cute.deref_arith_tuple_iter"(%379) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %381:2 = "cute.get_leaves"(%380) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %382 = "cute.get_scalars"(%381#0) : (!cute.int_tuple<"?">) -> i32
      %383 = "cute.get_scalars"(%381#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %384 = "cute.get_iter"(%373) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %385 = "cute.deref_arith_tuple_iter"(%384) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %386:2 = "cute.get_leaves"(%385) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %387 = "cute.get_scalars"(%386#0) : (!cute.int_tuple<"?">) -> i32
      %388 = "cute.get_scalars"(%386#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %389 = "cute.make_coord"(%386#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %390 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %391 = "cute.elem_less"(%389, %390) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %392 = "arith.extui"(%391) : (i1) -> i8
      %393 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%188, %393, %392) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %394 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %395 = "cute.slice"(%151, %394) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %396 = "cute.get_iter"(%395) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %397 = "cute.deref_arith_tuple_iter"(%396) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %398:2 = "cute.get_leaves"(%397) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %399 = "cute.get_scalars"(%398#0) : (!cute.int_tuple<"?">) -> i32
      %400 = "cute.get_scalars"(%398#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %401 = "cute.get_iter"(%395) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %402 = "cute.deref_arith_tuple_iter"(%401) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %403:2 = "cute.get_leaves"(%402) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %404 = "cute.get_scalars"(%403#0) : (!cute.int_tuple<"?">) -> i32
      %405 = "cute.get_scalars"(%403#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %406 = "cute.get_iter"(%395) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %407 = "cute.deref_arith_tuple_iter"(%406) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %408:2 = "cute.get_leaves"(%407) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %409 = "cute.get_scalars"(%408#0) : (!cute.int_tuple<"?">) -> i32
      %410 = "cute.get_scalars"(%408#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %411 = "arith.cmpi"(%409, %59) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%411) ({
        %961 = "cute.get_layout"(%142) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %962 = "cute.get_shape"(%961) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %963:4 = "cute.get_leaves"(%962) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %964 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %965 = "cute.get_shape"(%964) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %966:4 = "cute.get_leaves"(%965) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %967 = "cute.get_layout"(%142) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %968 = "cute.make_shape"() : () -> !cute.shape<"1">
        %969 = "cute.make_layout"(%968) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %970 = "cute.append_to_rank"(%967, %969) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %971 = "cute.make_view"(%143, %970) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %972 = "cute.get_iter"(%971) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %973 = "cute.get_layout"(%971) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %974 = "cute.get_shape"(%973) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %975:4 = "cute.get_leaves"(%974) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %976 = "cute.get_layout"(%971) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %977 = "cute.get_shape"(%976) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %978:4 = "cute.get_leaves"(%977) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %979 = "cute.group_modes"(%971) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %980 = "cute.get_iter"(%979) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %981 = "cute.get_iter"(%979) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %982 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %983 = "cute.make_shape"() : () -> !cute.shape<"1">
        %984 = "cute.make_layout"(%983) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %985 = "cute.append_to_rank"(%982, %984) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %986 = "cute.make_view"(%146, %985) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_smem_bf16_1
        %987 = "cute.get_iter"(%986) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %988 = "cute.get_layout"(%986) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %989 = "cute.get_shape"(%988) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %990:4 = "cute.get_leaves"(%989) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %991 = "cute.get_layout"(%986) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %992 = "cute.get_shape"(%991) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %993:4 = "cute.get_leaves"(%992) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %994 = "cute.group_modes"(%986) <{begin = 1 : i32, end = 3 : i32}> : (!memref_smem_bf16_1) -> !memref_smem_bf16_2
        %995 = "cute.get_iter"(%994) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %996 = "cute.get_iter"(%994) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %997 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %998 = "cute.make_shape"() : () -> !cute.shape<"1">
        %999 = "cute.make_layout"(%998) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %1000 = "cute.append_to_rank"(%997, %999) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1001 = "cute.make_view"(%190, %1000) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1002 = "cute.get_iter"(%1001) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1003 = "cute.get_layout"(%1001) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1004 = "cute.get_shape"(%1003) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1005:3 = "cute.get_leaves"(%1004) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1006 = "cute.get_layout"(%1001) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1007 = "cute.get_shape"(%1006) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1008:3 = "cute.get_leaves"(%1007) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1009 = "cute.group_modes"(%1001) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %1010 = "cute.get_iter"(%1009) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1011 = "cute.get_iter"(%1009) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1012 = "cute.get_layout"(%979) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1013 = "cute.get_shape"(%1012) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1014:4 = "cute.get_leaves"(%1013) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1015 = "cute.get_layout"(%994) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1016 = "cute.get_shape"(%1015) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1017:4 = "cute.get_leaves"(%1016) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1018 = "cute.size"(%979) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %1019 = "cute.get_leaves"(%1018) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1020 = "cute.size"(%994) <{mode = array<i32: 1>}> : (!memref_smem_bf16_2) -> !cute.int_tuple<"1">
        %1021 = "cute.get_leaves"(%1020) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%132, %979, %994, %1009) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_6, !memref_smem_bf16_2, !memref_rmem_i8_1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %412 = "cute.make_coord"(%49) : (i32) -> !cute.coord<"?">
      %413 = "cute.tiled.copy.partition_S"(%138, %114, %412) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %414 = "cute.get_iter"(%413) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %415 = "cute.deref_arith_tuple_iter"(%414) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %416:2 = "cute.get_leaves"(%415) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %417 = "cute.get_scalars"(%416#0) : (!cute.int_tuple<"?">) -> i32
      %418 = "cute.get_scalars"(%416#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %419 = "cute.size"(%413) <{mode = array<i32: 0, 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %420 = "cute.get_leaves"(%419) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %421 = "cute.size"(%413) <{mode = array<i32: 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %422 = "cute.get_leaves"(%421) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %423 = "cute.size"(%413) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %424 = "cute.get_leaves"(%423) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %425 = "cute.size"(%413) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %426 = "cute.get_leaves"(%425) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %427 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %428 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %429 = "cute.make_layout"(%427, %428) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(8,1,1)">, !cute.stride<"(1,0,1)">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %430 = "cute.memref.alloca"(%429) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %431 = "cute.get_iter"(%430) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %432 = "cute.get_iter"(%430) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %433 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %434 = "cute.get_shape"(%433) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %435:3 = "cute.get_leaves"(%434) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %436 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %437 = "cute.get_shape"(%436) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %438:3 = "cute.get_leaves"(%437) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %439 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %440 = "cute.slice"(%413, %439) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %441 = "cute.get_iter"(%440) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %442 = "cute.deref_arith_tuple_iter"(%441) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %443:2 = "cute.get_leaves"(%442) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %444 = "cute.get_scalars"(%443#0) : (!cute.int_tuple<"?">) -> i32
      %445 = "cute.get_scalars"(%443#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %446 = "cute.get_iter"(%440) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %447 = "cute.deref_arith_tuple_iter"(%446) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %448:2 = "cute.get_leaves"(%447) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %449 = "cute.get_scalars"(%448#0) : (!cute.int_tuple<"?">) -> i32
      %450 = "cute.get_scalars"(%448#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %451 = "cute.get_iter"(%440) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %452 = "cute.deref_arith_tuple_iter"(%451) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %453:2 = "cute.get_leaves"(%452) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %454 = "cute.get_scalars"(%453#0) : (!cute.int_tuple<"?">) -> i32
      %455 = "cute.get_scalars"(%453#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %456 = "cute.make_coord"(%453#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %457 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %458 = "cute.elem_less"(%456, %457) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %459 = "arith.extui"(%458) : (i1) -> i8
      %460 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%430, %460, %459) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %461 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %462 = "cute.get_shape"(%461) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %463:3 = "cute.get_leaves"(%462) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %464 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %465 = "cute.slice"(%413, %464) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %466 = "cute.get_iter"(%465) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %467 = "cute.deref_arith_tuple_iter"(%466) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %468:2 = "cute.get_leaves"(%467) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %469 = "cute.get_scalars"(%468#0) : (!cute.int_tuple<"?">) -> i32
      %470 = "cute.get_scalars"(%468#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %471 = "cute.get_iter"(%465) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %472 = "cute.deref_arith_tuple_iter"(%471) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %473:2 = "cute.get_leaves"(%472) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %474 = "cute.get_scalars"(%473#0) : (!cute.int_tuple<"?">) -> i32
      %475 = "cute.get_scalars"(%473#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %476 = "cute.get_iter"(%465) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %477 = "cute.deref_arith_tuple_iter"(%476) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %478:2 = "cute.get_leaves"(%477) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %479 = "cute.get_scalars"(%478#0) : (!cute.int_tuple<"?">) -> i32
      %480 = "cute.get_scalars"(%478#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %481 = "cute.make_coord"(%478#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %482 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %483 = "cute.elem_less"(%481, %482) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %484 = "arith.extui"(%483) : (i1) -> i8
      %485 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%430, %485, %484) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %486 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %487 = "cute.get_shape"(%486) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %488:3 = "cute.get_leaves"(%487) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %489 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %490 = "cute.slice"(%413, %489) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %491 = "cute.get_iter"(%490) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %492 = "cute.deref_arith_tuple_iter"(%491) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %493:2 = "cute.get_leaves"(%492) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %494 = "cute.get_scalars"(%493#0) : (!cute.int_tuple<"?">) -> i32
      %495 = "cute.get_scalars"(%493#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %496 = "cute.get_iter"(%490) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %497 = "cute.deref_arith_tuple_iter"(%496) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %498:2 = "cute.get_leaves"(%497) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %499 = "cute.get_scalars"(%498#0) : (!cute.int_tuple<"?">) -> i32
      %500 = "cute.get_scalars"(%498#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %501 = "cute.get_iter"(%490) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %502 = "cute.deref_arith_tuple_iter"(%501) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %503:2 = "cute.get_leaves"(%502) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %504 = "cute.get_scalars"(%503#0) : (!cute.int_tuple<"?">) -> i32
      %505 = "cute.get_scalars"(%503#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %506 = "cute.make_coord"(%503#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %507 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %508 = "cute.elem_less"(%506, %507) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %509 = "arith.extui"(%508) : (i1) -> i8
      %510 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%430, %510, %509) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %511 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %512 = "cute.get_shape"(%511) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %513:3 = "cute.get_leaves"(%512) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %514 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %515 = "cute.slice"(%413, %514) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %516 = "cute.get_iter"(%515) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %517 = "cute.deref_arith_tuple_iter"(%516) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %518:2 = "cute.get_leaves"(%517) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %519 = "cute.get_scalars"(%518#0) : (!cute.int_tuple<"?">) -> i32
      %520 = "cute.get_scalars"(%518#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %521 = "cute.get_iter"(%515) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %522 = "cute.deref_arith_tuple_iter"(%521) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %523:2 = "cute.get_leaves"(%522) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %524 = "cute.get_scalars"(%523#0) : (!cute.int_tuple<"?">) -> i32
      %525 = "cute.get_scalars"(%523#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %526 = "cute.get_iter"(%515) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %527 = "cute.deref_arith_tuple_iter"(%526) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %528:2 = "cute.get_leaves"(%527) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %529 = "cute.get_scalars"(%528#0) : (!cute.int_tuple<"?">) -> i32
      %530 = "cute.get_scalars"(%528#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %531 = "cute.make_coord"(%528#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %532 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %533 = "cute.elem_less"(%531, %532) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %534 = "arith.extui"(%533) : (i1) -> i8
      %535 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%430, %535, %534) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %536 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %537 = "cute.get_shape"(%536) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %538:3 = "cute.get_leaves"(%537) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %539 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %540 = "cute.slice"(%413, %539) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %541 = "cute.get_iter"(%540) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %542 = "cute.deref_arith_tuple_iter"(%541) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %543:2 = "cute.get_leaves"(%542) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %544 = "cute.get_scalars"(%543#0) : (!cute.int_tuple<"?">) -> i32
      %545 = "cute.get_scalars"(%543#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %546 = "cute.get_iter"(%540) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %547 = "cute.deref_arith_tuple_iter"(%546) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %548:2 = "cute.get_leaves"(%547) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %549 = "cute.get_scalars"(%548#0) : (!cute.int_tuple<"?">) -> i32
      %550 = "cute.get_scalars"(%548#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %551 = "cute.get_iter"(%540) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %552 = "cute.deref_arith_tuple_iter"(%551) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %553:2 = "cute.get_leaves"(%552) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %554 = "cute.get_scalars"(%553#0) : (!cute.int_tuple<"?">) -> i32
      %555 = "cute.get_scalars"(%553#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %556 = "cute.make_coord"(%553#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %557 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %558 = "cute.elem_less"(%556, %557) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %559 = "arith.extui"(%558) : (i1) -> i8
      %560 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%430, %560, %559) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %561 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %562 = "cute.get_shape"(%561) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %563:3 = "cute.get_leaves"(%562) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %564 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %565 = "cute.slice"(%413, %564) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %566 = "cute.get_iter"(%565) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %567 = "cute.deref_arith_tuple_iter"(%566) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %568:2 = "cute.get_leaves"(%567) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %569 = "cute.get_scalars"(%568#0) : (!cute.int_tuple<"?">) -> i32
      %570 = "cute.get_scalars"(%568#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %571 = "cute.get_iter"(%565) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %572 = "cute.deref_arith_tuple_iter"(%571) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %573:2 = "cute.get_leaves"(%572) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %574 = "cute.get_scalars"(%573#0) : (!cute.int_tuple<"?">) -> i32
      %575 = "cute.get_scalars"(%573#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %576 = "cute.get_iter"(%565) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %577 = "cute.deref_arith_tuple_iter"(%576) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %578:2 = "cute.get_leaves"(%577) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %579 = "cute.get_scalars"(%578#0) : (!cute.int_tuple<"?">) -> i32
      %580 = "cute.get_scalars"(%578#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %581 = "cute.make_coord"(%578#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %582 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %583 = "cute.elem_less"(%581, %582) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %584 = "arith.extui"(%583) : (i1) -> i8
      %585 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%430, %585, %584) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %586 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %587 = "cute.get_shape"(%586) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %588:3 = "cute.get_leaves"(%587) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %589 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %590 = "cute.slice"(%413, %589) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %591 = "cute.get_iter"(%590) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %592 = "cute.deref_arith_tuple_iter"(%591) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %593:2 = "cute.get_leaves"(%592) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %594 = "cute.get_scalars"(%593#0) : (!cute.int_tuple<"?">) -> i32
      %595 = "cute.get_scalars"(%593#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %596 = "cute.get_iter"(%590) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %597 = "cute.deref_arith_tuple_iter"(%596) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %598:2 = "cute.get_leaves"(%597) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %599 = "cute.get_scalars"(%598#0) : (!cute.int_tuple<"?">) -> i32
      %600 = "cute.get_scalars"(%598#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %601 = "cute.get_iter"(%590) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %602 = "cute.deref_arith_tuple_iter"(%601) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %603:2 = "cute.get_leaves"(%602) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %604 = "cute.get_scalars"(%603#0) : (!cute.int_tuple<"?">) -> i32
      %605 = "cute.get_scalars"(%603#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %606 = "cute.make_coord"(%603#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %607 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %608 = "cute.elem_less"(%606, %607) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %609 = "arith.extui"(%608) : (i1) -> i8
      %610 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%430, %610, %609) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %611 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %612 = "cute.get_shape"(%611) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %613:3 = "cute.get_leaves"(%612) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %614 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %615 = "cute.slice"(%413, %614) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %616 = "cute.get_iter"(%615) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %617 = "cute.deref_arith_tuple_iter"(%616) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %618:2 = "cute.get_leaves"(%617) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %619 = "cute.get_scalars"(%618#0) : (!cute.int_tuple<"?">) -> i32
      %620 = "cute.get_scalars"(%618#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %621 = "cute.get_iter"(%615) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %622 = "cute.deref_arith_tuple_iter"(%621) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %623:2 = "cute.get_leaves"(%622) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %624 = "cute.get_scalars"(%623#0) : (!cute.int_tuple<"?">) -> i32
      %625 = "cute.get_scalars"(%623#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %626 = "cute.get_iter"(%615) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %627 = "cute.deref_arith_tuple_iter"(%626) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %628:2 = "cute.get_leaves"(%627) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %629 = "cute.get_scalars"(%628#0) : (!cute.int_tuple<"?">) -> i32
      %630 = "cute.get_scalars"(%628#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %631 = "cute.make_coord"(%628#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %632 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %633 = "cute.elem_less"(%631, %632) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %634 = "arith.extui"(%633) : (i1) -> i8
      %635 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%430, %635, %634) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %636 = "cute.get_layout"(%168) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %637 = "cute.get_shape"(%636) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %638:4 = "cute.get_leaves"(%637) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %639 = "cute.get_layout"(%172) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %640 = "cute.get_shape"(%639) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %641:4 = "cute.get_leaves"(%640) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %642 = "cute.get_layout"(%168) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %643 = "cute.make_shape"() : () -> !cute.shape<"1">
      %644 = "cute.make_layout"(%643) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %645 = "cute.append_to_rank"(%642, %644) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %646 = "cute.make_view"(%169, %645) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
      %647 = "cute.get_iter"(%646) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %648 = "cute.get_layout"(%646) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %649 = "cute.get_shape"(%648) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %650:4 = "cute.get_leaves"(%649) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %651 = "cute.get_layout"(%646) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %652 = "cute.get_shape"(%651) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %653:4 = "cute.get_leaves"(%652) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %654 = "cute.group_modes"(%646) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
      %655 = "cute.get_iter"(%654) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %656 = "cute.get_iter"(%654) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %657 = "cute.get_layout"(%172) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %658 = "cute.make_shape"() : () -> !cute.shape<"1">
      %659 = "cute.make_layout"(%658) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %660 = "cute.append_to_rank"(%657, %659) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %661 = "cute.make_view"(%174, %660) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %662 = "cute.get_iter"(%661) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %663 = "cute.get_layout"(%661) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %664 = "cute.get_shape"(%663) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %665:4 = "cute.get_leaves"(%664) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %666 = "cute.get_layout"(%661) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %667 = "cute.get_shape"(%666) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %668:4 = "cute.get_leaves"(%667) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %669 = "cute.group_modes"(%661) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
      %670 = "cute.get_iter"(%669) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %671 = "cute.get_iter"(%669) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %672 = "cute.get_layout"(%430) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %673 = "cute.make_shape"() : () -> !cute.shape<"1">
      %674 = "cute.make_layout"(%673) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %675 = "cute.append_to_rank"(%672, %674) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %676 = "cute.make_view"(%432, %675) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %677 = "cute.get_iter"(%676) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %678 = "cute.get_layout"(%676) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %679 = "cute.get_shape"(%678) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %680:3 = "cute.get_leaves"(%679) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %681 = "cute.get_layout"(%676) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %682 = "cute.get_shape"(%681) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %683:3 = "cute.get_leaves"(%682) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %684 = "cute.group_modes"(%676) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %685 = "cute.get_iter"(%684) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %686 = "cute.get_iter"(%684) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %687 = "cute.get_layout"(%654) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %688 = "cute.get_shape"(%687) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %689:4 = "cute.get_leaves"(%688) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %690 = "cute.get_layout"(%669) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %691 = "cute.get_shape"(%690) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %692:4 = "cute.get_leaves"(%691) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %693 = "cute.size"(%654) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
      %694 = "cute.get_leaves"(%693) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %695 = "cute.size"(%669) <{mode = array<i32: 1>}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
      %696 = "cute.get_leaves"(%695) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%133, %654, %669, %684) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_6, !memref_rmem_bf16_1, !memref_rmem_i8_1) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %697 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %698 = "cute.get_shape"(%697) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %699:4 = "cute.get_leaves"(%698) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %700 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %701 = "cute.get_shape"(%700) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %702:4 = "cute.get_leaves"(%701) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %703 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %704 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %705 = "cute.right_inverse"(%704) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %706 = "cute.composition"(%703, %705) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %707 = "cute.coalesce"(%706) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %708 = "cute.get_shape"(%707) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %709:2 = "cute.get_leaves"(%708) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %710 = "cute.get_stride"(%707) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %711:2 = "cute.get_leaves"(%710) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %712 = "cute.get_shape"(%707) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %713:2 = "cute.get_leaves"(%712) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %714 = "cute.get_shape"(%707) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %715:2 = "cute.get_leaves"(%714) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %716 = "cute.get"(%707) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %717 = "cute.composition"(%705, %716) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %718 = "cute.size"(%717) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %719 = "cute.get_leaves"(%718) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %720 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %721 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %722 = "cute.logical_divide"(%145, %717) : (!memref_smem_bf16_1, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %723 = "cute.get_iter"(%722) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %724 = "cute.get_iter"(%722) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %725 = "cute.logical_divide"(%159, %717) : (!memref_rmem_bf16_, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %726 = "cute.get_iter"(%725) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %727 = "cute.get_iter"(%725) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %728 = "cute.make_shape"() : () -> !cute.shape<"8">
      %729 = "cute.make_layout"(%728) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %730 = "cute.logical_divide"(%722, %729) : (!memref_smem_bf16_3, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %731 = "cute.get_iter"(%730) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %732 = "cute.get_iter"(%730) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %733 = "cute.make_shape"() : () -> !cute.shape<"8">
      %734 = "cute.make_layout"(%733) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %735 = "cute.logical_divide"(%725, %734) : (!memref_rmem_bf16_2, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %736 = "cute.get_iter"(%735) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %737 = "cute.get_iter"(%735) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %738 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      "cute.copy"(%738, %730, %735) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2) -> ()
      %739 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %740 = "cute.get_shape"(%739) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %741:4 = "cute.get_leaves"(%740) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %742 = "cute.memref.load_vec"(%159) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %743 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %744 = "cute.get_shape"(%743) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %745:4 = "cute.get_leaves"(%744) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %746 = "arith.extf"(%742) : (vector<64xbf16>) -> vector<64xf32>
      %747 = "arith.mulf"(%746, %746) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %748 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %749 = "vector.reduction"(%747, %748) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %750 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %751 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %752 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %753 = "nvvm.shfl.sync"(%750, %749, %751, %752) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %754 = "arith.addf"(%753, %749) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %755 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %756 = "nvvm.shfl.sync"(%750, %754, %755, %752) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %757 = "arith.addf"(%754, %756) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %758 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %759 = "nvvm.shfl.sync"(%750, %757, %758, %752) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %760 = "arith.addf"(%757, %759) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %761 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %762 = "nvvm.shfl.sync"(%750, %760, %761, %752) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %763 = "arith.addf"(%760, %762) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %764 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %765 = "nvvm.shfl.sync"(%750, %763, %764, %752) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %766 = "arith.addf"(%763, %765) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %767 = "nvvm.read.ptx.sreg.laneid"() : () -> i32
      %768 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %769 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %770 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %771 = "nvvm.read.ptx.sreg.ntid.x"() : () -> i32
      %772 = "nvvm.read.ptx.sreg.ntid.y"() : () -> i32
      %773 = "arith.muli"(%769, %771) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %774 = "arith.addi"(%768, %773) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %775 = "arith.muli"(%770, %771) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %776 = "arith.muli"(%775, %772) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %777 = "arith.addi"(%774, %776) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %778 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %779 = "arith.floordivsi"(%777, %778) : (i32, i32) -> i32
      %780 = "cute.get_layout"(%92) : (!memref_smem_f32_) -> !cute.layout<"(2,2):(1,2)">
      %781 = "cute.get_shape"(%780) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %782:2 = "cute.get_leaves"(%781) : (!cute.shape<"(2,2)">) -> (!cute.shape<"2">, !cute.shape<"2">)
      %783 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
      %784 = "cute.size"(%783) <{mode = array<i32>}> : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %785 = "cute.get_leaves"(%784) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %786 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %787 = "arith.floordivsi"(%779, %786) : (i32, i32) -> i32
      %788 = "arith.remsi"(%779, %786) : (i32, i32) -> i32
      %789 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %790 = "arith.cmpi"(%767, %789) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %791 = "scf.if"(%790) ({
        %959 = "cute.get_iter"(%92) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        %960 = "cute.make_coord"(%787, %788) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%92, %960, %766) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"(%92) : (!memref_smem_f32_) -> ()
      }, {
        %958 = "cute.get_iter"(%92) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        "scf.yield"(%92) : (!memref_smem_f32_) -> ()
      }) : (i1) -> !memref_smem_f32_
      %792 = "cute.get_iter"(%791) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %793 = "cute.get_iter"(%791) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %794 = "cute.get_iter"(%791) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %795 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%795) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %796 = "arith.cmpi"(%767, %786) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %797 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %798 = "scf.if"(%796) ({
        %956 = "cute.make_coord"(%787, %767) : (i32, i32) -> !cute.coord<"(?,?)">
        %957 = "cute.memref.load"(%791, %956) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%957) : (f32) -> ()
      }, {
        "scf.yield"(%797) : (f32) -> ()
      }) : (i1) -> f32
      %799 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %800 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %801 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %802 = "nvvm.shfl.sync"(%799, %798, %800, %801) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %803 = "arith.addf"(%798, %802) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %804 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %805 = "nvvm.shfl.sync"(%799, %803, %804, %801) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %806 = "arith.addf"(%803, %805) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %807 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %808 = "nvvm.shfl.sync"(%799, %806, %807, %801) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %809 = "arith.addf"(%806, %808) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %810 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %811 = "nvvm.shfl.sync"(%799, %809, %810, %801) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %812 = "arith.addf"(%809, %811) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %813 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %814 = "nvvm.shfl.sync"(%799, %812, %813, %801) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %815 = "arith.addf"(%812, %814) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %816 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %817 = "arith.divf"(%815, %816) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %818 = "arith.addf"(%817, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %819 = "math.rsqrt"(%818) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      %820 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%820) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %821 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %822 = "cute.get_shape"(%821) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %823:4 = "cute.get_leaves"(%822) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %824 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %825 = "cute.get_shape"(%824) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %826:4 = "cute.get_leaves"(%825) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %827 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %828 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %829 = "cute.right_inverse"(%828) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %830 = "cute.composition"(%827, %829) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %831 = "cute.coalesce"(%830) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %832 = "cute.get_shape"(%831) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %833:2 = "cute.get_leaves"(%832) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %834 = "cute.get_stride"(%831) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %835:2 = "cute.get_leaves"(%834) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %836 = "cute.get_shape"(%831) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %837:2 = "cute.get_leaves"(%836) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %838 = "cute.get_shape"(%831) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %839:2 = "cute.get_leaves"(%838) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %840 = "cute.get"(%831) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %841 = "cute.composition"(%829, %840) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %842 = "cute.size"(%841) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %843 = "cute.get_leaves"(%842) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %844 = "cute.get_layout"(%145) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %845 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %846 = "cute.logical_divide"(%145, %841) : (!memref_smem_bf16_1, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %847 = "cute.get_iter"(%846) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %848 = "cute.get_iter"(%846) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %849 = "cute.logical_divide"(%159, %841) : (!memref_rmem_bf16_, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %850 = "cute.get_iter"(%849) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %851 = "cute.get_iter"(%849) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %852 = "cute.make_shape"() : () -> !cute.shape<"8">
      %853 = "cute.make_layout"(%852) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %854 = "cute.logical_divide"(%846, %853) : (!memref_smem_bf16_3, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %855 = "cute.get_iter"(%854) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %856 = "cute.get_iter"(%854) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %857 = "cute.make_shape"() : () -> !cute.shape<"8">
      %858 = "cute.make_layout"(%857) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %859 = "cute.logical_divide"(%849, %858) : (!memref_rmem_bf16_2, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %860 = "cute.get_iter"(%859) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %861 = "cute.get_iter"(%859) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %862 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      "cute.copy"(%862, %854, %859) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2) -> ()
      %863 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %864 = "cute.get_shape"(%863) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %865:4 = "cute.get_leaves"(%864) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %866 = "cute.memref.load_vec"(%159) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %867 = "cute.get_layout"(%159) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %868 = "cute.get_shape"(%867) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %869:4 = "cute.get_leaves"(%868) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %870 = "arith.extf"(%866) : (vector<64xbf16>) -> vector<64xf32>
      %871 = "vector.broadcast"(%819) : (f32) -> vector<64xf32>
      %872 = "arith.mulf"(%870, %871) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %873 = "cute.get_layout"(%175) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %874 = "cute.get_shape"(%873) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %875:4 = "cute.get_leaves"(%874) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %876 = "cute.memref.load_vec"(%175) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %877 = "cute.get_layout"(%175) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %878 = "cute.get_shape"(%877) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %879:4 = "cute.get_leaves"(%878) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %880 = "arith.extf"(%876) : (vector<64xbf16>) -> vector<64xf32>
      %881 = "arith.mulf"(%872, %880) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %882 = "arith.truncf"(%881) : (vector<64xf32>) -> vector<64xbf16>
      %883 = "cute.get_layout"(%164) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %884 = "cute.get_shape"(%883) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %885:4 = "cute.get_leaves"(%884) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %886 = "cute.get_layout"(%164) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %887 = "cute.get_shape"(%886) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %888:4 = "cute.get_leaves"(%887) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %889 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %890 = "cute.size"(%889) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %891 = "cute.get_leaves"(%890) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      %892 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %893 = "cute.size"(%892) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %894 = "cute.get_leaves"(%893) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      "cute.memref.store_vec"(%882, %164) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%411) ({
        %895 = "cute.get_layout"(%164) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %896 = "cute.get_shape"(%895) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %897:4 = "cute.get_leaves"(%896) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %898 = "cute.get_layout"(%148) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %899 = "cute.get_shape"(%898) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %900:4 = "cute.get_leaves"(%899) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %901 = "cute.get_layout"(%164) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %902 = "cute.make_shape"() : () -> !cute.shape<"1">
        %903 = "cute.make_layout"(%902) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %904 = "cute.append_to_rank"(%901, %903) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %905 = "cute.make_view"(%166, %904) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
        %906 = "cute.get_iter"(%905) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %907 = "cute.get_layout"(%905) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %908 = "cute.get_shape"(%907) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %909:4 = "cute.get_leaves"(%908) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %910 = "cute.get_layout"(%905) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %911 = "cute.get_shape"(%910) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %912:4 = "cute.get_leaves"(%911) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %913 = "cute.group_modes"(%905) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
        %914 = "cute.get_iter"(%913) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %915 = "cute.get_iter"(%913) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %916 = "cute.get_layout"(%148) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %917 = "cute.make_shape"() : () -> !cute.shape<"1">
        %918 = "cute.make_layout"(%917) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %919 = "cute.append_to_rank"(%916, %918) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %920 = "cute.make_view"(%149, %919) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %921 = "cute.get_iter"(%920) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %922 = "cute.get_layout"(%920) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %923 = "cute.get_shape"(%922) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %924:4 = "cute.get_leaves"(%923) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %925 = "cute.get_layout"(%920) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %926 = "cute.get_shape"(%925) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %927:4 = "cute.get_leaves"(%926) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %928 = "cute.group_modes"(%920) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %929 = "cute.get_iter"(%928) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %930 = "cute.get_iter"(%928) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %931 = "cute.get_layout"(%188) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %932 = "cute.make_shape"() : () -> !cute.shape<"1">
        %933 = "cute.make_layout"(%932) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %934 = "cute.append_to_rank"(%931, %933) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %935 = "cute.make_view"(%190, %934) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %936 = "cute.get_iter"(%935) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %937 = "cute.get_layout"(%935) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %938 = "cute.get_shape"(%937) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %939:3 = "cute.get_leaves"(%938) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %940 = "cute.get_layout"(%935) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %941 = "cute.get_shape"(%940) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %942:3 = "cute.get_leaves"(%941) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %943 = "cute.group_modes"(%935) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %944 = "cute.get_iter"(%943) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %945 = "cute.get_iter"(%943) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %946 = "cute.get_layout"(%913) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %947 = "cute.get_shape"(%946) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %948:4 = "cute.get_leaves"(%947) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %949 = "cute.get_layout"(%928) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %950 = "cute.get_shape"(%949) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %951:4 = "cute.get_leaves"(%950) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %952 = "cute.size"(%913) <{mode = array<i32: 1>}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
        %953 = "cute.get_leaves"(%952) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %954 = "cute.size"(%928) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %955 = "cute.get_leaves"(%954) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%134, %913, %928, %943) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_1, !memref_gmem_bf16_6, !memref_rmem_i8_1) -> ()
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
    %12 = "cute.make_layout"(%10, %11) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(4096)">, !cute.stride<"(1)">) -> !cute.layout<"(4096):(1)">
    %13 = "cute.make_view"(%arg1, %12) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(4096):(1)">) -> !memref_gmem_bf16_1
    %14 = "cute.get_iter"(%13) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
    %15 = "cute.make_shape"() : () -> !cute.shape<"((64,2),(8,8))">
    %16 = "cute.make_stride"() : () -> !cute.stride<"((16,1),(2,1024))">
    %17 = "cute.make_layout"(%15, %16) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,2),(8,8))">, !cute.stride<"((16,1),(2,1024))">) -> !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
    %18 = "cute.make_int_tuple"(%arg3) : (i32) -> !cute.int_tuple<"?">
    %19 = "cute.make_tile"() : () -> !cute.tile<"2:1">
    %20 = "cute.ceil_div"(%18, %19) : (!cute.int_tuple<"?">, !cute.tile<"2:1">) -> !cute.int_tuple<"?">
    %21 = "cute.get_leaves"(%20) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %22 = "cute.get_scalars"(%21) : (!cute.int_tuple<"?">) -> i32
    %23 = "cute.get_layout"(%3) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
    %24 = "cute.get_layout"(%13) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
    %25 = "cute.get_layout"(%8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
    %26 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
    %27 = "arith.extsi"(%26) : (i32) -> i64
    %28 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %29 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %30 = "cuda.launch_cfg.create"(%28, %29, %29, %27, %22, %29, %29, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %31 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%30, %31) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %32 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%30, %32) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %33 = "cuda.launch_ex"(%30, %3, %13, %8, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %34 = "cuda.cast"(%33) : (!cuda.result) -> i32
    "cuda.return_if_error"(%34) : (i32) -> ()
    %35 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%35) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
