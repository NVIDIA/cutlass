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
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}, {}], function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32, !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> (), sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0"}> ({
    ^bb0(%arg6: !memref_gmem_bf16_, %arg7: !memref_gmem_bf16_1, %arg8: !memref_gmem_bf16_, %arg9: f32, %arg10: !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">):
      %36 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %37 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %38 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %39 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %40 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %41 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %42 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %43 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %44 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %45 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %46 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %47 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %48 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %49 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %50 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %51 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %52 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %53 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %54 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %55 = "cute.get_shape"(%54) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %56:2 = "cute.get_leaves"(%55) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %57 = "cute.to_int_tuple"(%56#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %58 = "cute.get_scalars"(%57) : (!cute.int_tuple<"?">) -> i32
      %59 = "cute.get_shape"(%arg10) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %60:4 = "cute.get_leaves"(%59) : (!cute.shape<"((64,2),(8,8))">) -> (!cute.shape<"64">, !cute.shape<"2">, !cute.shape<"8">, !cute.shape<"8">)
      %61 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %62 = "cute.make_shape"() : () -> !cute.shape<"(2,4096)">
      %63 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
      %64 = "cute.make_ordered_layout"(%62, %63) : (!cute.shape<"(2,4096)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(2,4096):(4096,1)">
      %65 = "cute.make_coord"() : () -> !cute.coord<"0">
      %66 = "cute.crd2idx"(%65, %64) : (!cute.coord<"0">, !cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"0">
      %67 = "cute.get_leaves"(%66) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %68 = "cute.cosize"(%64) <{mode = array<i32>}> : (!cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"8192">
      %69 = "cute.get_leaves"(%68) : (!cute.int_tuple<"8192">) -> !cute.int_tuple<"8192">
      %70 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16384">
      %71 = "cute.add_offset"(%61, %70) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %72 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %73 = "arith.constant"() <{value = 16384 : i32}> : () -> i32
      %74 = "arith.cmpi"(%72, %73) <{predicate = 5 : i64}> : (i32, i32) -> i1
      "cf.assert"(%74) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16384 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %75 = "cute.recast_iter"(%61) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %76 = "cute.make_view"(%75, %64) : (!cute.ptr<bf16, smem, align<1024>>, !cute.layout<"(2,4096):(4096,1)">) -> !memref_smem_bf16_
      %77 = "cute.get_iter"(%76) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %78 = "cute.make_shape"() : () -> !cute.shape<"(2,2)">
      %79 = "cute.make_layout"(%78) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(2,2)">) -> !cute.layout<"(2,2):(1,2)">
      %80 = "cute.make_coord"() : () -> !cute.coord<"0">
      %81 = "cute.crd2idx"(%80, %79) : (!cute.coord<"0">, !cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"0">
      %82 = "cute.get_leaves"(%81) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %83 = "cute.cosize"(%79) <{mode = array<i32>}> : (!cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"4">
      %84 = "cute.get_leaves"(%83) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %85 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
      %86 = "cute.add_offset"(%71, %85) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i8, smem, align<16>>
      %87 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %88 = "arith.constant"() <{value = 16400 : i32}> : () -> i32
      %89 = "arith.cmpi"(%87, %88) <{predicate = 5 : i64}> : (i32, i32) -> i1
      "cf.assert"(%89) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16400 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %90 = "cute.recast_iter"(%71) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %91 = "cute.make_view"(%90, %79) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %92 = "cute.get_iter"(%91) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %93 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %94 = "cute.get_shape"(%93) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %95:2 = "cute.get_leaves"(%94) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %96 = "cute.to_int_tuple"(%95#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %97 = "cute.get_scalars"(%96) : (!cute.int_tuple<"?">) -> i32
      %98 = "cute.make_shape"(%96) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %99 = "cute.make_identity_tensor"(%98) : (!cute.shape<"(?,4096)">) -> !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %100 = "cute.get_iter"(%99) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %101 = "cute.deref_arith_tuple_iter"(%100) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %102:2 = "cute.get_leaves"(%101) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %103 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %104 = "cute.make_coord"(%51) : (i32) -> !cute.coord<"(?,0)">
      %105 = "cute.local_tile"(%arg6, %103, %104) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %106 = "cute.get_iter"(%105) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %107 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %108 = "cute.make_coord"(%51) : (i32) -> !cute.coord<"(?,0)">
      %109 = "cute.local_tile"(%arg8, %107, %108) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %110 = "cute.get_iter"(%109) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %111 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %112 = "cute.make_coord"(%51) : (i32) -> !cute.coord<"(?,0)">
      %113 = "cute.local_tile"(%99, %111, %112) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %114 = "cute.get_iter"(%113) : (!cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %115 = "cute.deref_arith_tuple_iter"(%114) : (!cute.arith_tuple_iter<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %116:2 = "cute.get_leaves"(%115) : (!cute.int_tuple<"(?{div=2},0)">) -> (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"0">)
      %117 = "cute.get_scalars"(%116#0) : (!cute.int_tuple<"?{div=2}">) -> i32
      %118 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_1) -> !cute.layout<"(4096):(1)">
      %119 = "cute.make_shape"() : () -> !cute.shape<"(2)">
      %120 = "cute.make_stride"() : () -> !cute.stride<"(0)">
      %121 = "cute.make_layout"(%119, %120) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(0)">) -> !cute.layout<"(2):(0)">
      %122 = "cute.get_shape"(%118) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %123 = "cute.get_leaves"(%122) : (!cute.shape<"(4096)">) -> !cute.shape<"4096">
      %124 = "cute.prepend_to_rank"(%118, %121) <{rank = 2 : si32}> : (!cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">) -> !cute.layout<"((2),4096):((0),1)">
      %125 = "cute.make_view"(%40, %124) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((2),4096):((0),1)">) -> !memref_gmem_bf16_3
      %126 = "cute.get_iter"(%125) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %127 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %128 = "cute.make_coord"() : () -> !cute.coord<"(0,0)">
      %129 = "cute.local_tile"(%125, %127, %128) <{operandSegmentSizes = array<i32: 1, 1, 1>}> : (!memref_gmem_bf16_3, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(0,0)">) -> !memref_gmem_bf16_4
      %130 = "cute.get_iter"(%129) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %131 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %132 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %133 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %134 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %135 = "cute.make_tiled_copy"(%131) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %136 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %137 = "cute.make_tiled_copy"(%132) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %138 = "cute.make_tile"() : () -> !cute.tile<"[2:1;4096:1]">
      %139 = "cute.make_tiled_copy"(%133) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %140 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %141 = "cute.tiled.copy.partition_S"(%135, %105, %140) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %142 = "cute.get_iter"(%141) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %143 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %144 = "cute.tiled.copy.partition_D"(%135, %76, %143) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %145 = "cute.get_iter"(%144) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
      %146 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %147 = "cute.tiled.copy.partition_D"(%139, %109, %146) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %148 = "cute.get_iter"(%147) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %149 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %150 = "cute.tiled.copy.partition_S"(%135, %113, %149) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %151 = "cute.get_iter"(%150) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %152 = "cute.deref_arith_tuple_iter"(%151) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %153:2 = "cute.get_leaves"(%152) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %154 = "cute.get_scalars"(%153#0) : (!cute.int_tuple<"?">) -> i32
      %155 = "cute.get_scalars"(%153#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %156 = "cute.get_layout"(%141) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %157 = "cute.make_layout_like"(%156) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %158 = "cute.memref.alloca"(%157) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %159 = "cute.get_iter"(%158) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %160 = "cute.get_iter"(%158) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %161 = "cute.get_layout"(%147) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %162 = "cute.make_layout_like"(%161) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %163 = "cute.memref.alloca"(%162) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %164 = "cute.get_iter"(%163) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %165 = "cute.get_iter"(%163) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %166 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %167 = "cute.tiled.copy.partition_S"(%137, %129, %166) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %168 = "cute.get_iter"(%167) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %169 = "cute.get_layout"(%167) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %170 = "cute.make_layout_like"(%169) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %171 = "cute.memref.alloca"(%170) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %172 = "cute.get_iter"(%171) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %173 = "cute.get_iter"(%171) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %174 = "cute.tiled.copy.retile"(%135, %171) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %175 = "cute.get_iter"(%174) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %176 = "cute.size"(%150) <{mode = array<i32: 0, 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %177 = "cute.get_leaves"(%176) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %178 = "cute.size"(%150) <{mode = array<i32: 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %179 = "cute.get_leaves"(%178) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %180 = "cute.size"(%150) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %181 = "cute.get_leaves"(%180) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %182 = "cute.size"(%150) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %183 = "cute.get_leaves"(%182) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %184 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %185 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %186 = "cute.make_layout"(%184, %185) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(8,1,1)">, !cute.stride<"(1,0,1)">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %187 = "cute.memref.alloca"(%186) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %188 = "cute.get_iter"(%187) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %189 = "cute.get_iter"(%187) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %190 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %191 = "cute.get_shape"(%190) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %192:3 = "cute.get_leaves"(%191) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %193 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %194 = "cute.get_shape"(%193) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %195:3 = "cute.get_leaves"(%194) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %196 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %197 = "cute.slice"(%150, %196) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %198 = "cute.get_iter"(%197) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %199 = "cute.deref_arith_tuple_iter"(%198) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %200:2 = "cute.get_leaves"(%199) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %201 = "cute.get_scalars"(%200#0) : (!cute.int_tuple<"?">) -> i32
      %202 = "cute.get_scalars"(%200#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %203 = "cute.get_iter"(%197) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %204 = "cute.deref_arith_tuple_iter"(%203) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %205:2 = "cute.get_leaves"(%204) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %206 = "cute.get_scalars"(%205#0) : (!cute.int_tuple<"?">) -> i32
      %207 = "cute.get_scalars"(%205#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %208 = "cute.get_iter"(%197) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %209 = "cute.deref_arith_tuple_iter"(%208) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %210:2 = "cute.get_leaves"(%209) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %211 = "cute.get_scalars"(%210#0) : (!cute.int_tuple<"?">) -> i32
      %212 = "cute.get_scalars"(%210#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %213 = "cute.make_coord"(%210#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %214 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %215 = "cute.elem_less"(%213, %214) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %216 = "arith.extui"(%215) : (i1) -> i8
      %217 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%187, %217, %216) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %218 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %219 = "cute.get_shape"(%218) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %220:3 = "cute.get_leaves"(%219) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %221 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %222 = "cute.slice"(%150, %221) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %223 = "cute.get_iter"(%222) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %224 = "cute.deref_arith_tuple_iter"(%223) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %225:2 = "cute.get_leaves"(%224) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %226 = "cute.get_scalars"(%225#0) : (!cute.int_tuple<"?">) -> i32
      %227 = "cute.get_scalars"(%225#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %228 = "cute.get_iter"(%222) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %229 = "cute.deref_arith_tuple_iter"(%228) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %230:2 = "cute.get_leaves"(%229) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %231 = "cute.get_scalars"(%230#0) : (!cute.int_tuple<"?">) -> i32
      %232 = "cute.get_scalars"(%230#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %233 = "cute.get_iter"(%222) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %234 = "cute.deref_arith_tuple_iter"(%233) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %235:2 = "cute.get_leaves"(%234) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %236 = "cute.get_scalars"(%235#0) : (!cute.int_tuple<"?">) -> i32
      %237 = "cute.get_scalars"(%235#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %238 = "cute.make_coord"(%235#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %239 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %240 = "cute.elem_less"(%238, %239) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %241 = "arith.extui"(%240) : (i1) -> i8
      %242 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%187, %242, %241) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %243 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %244 = "cute.get_shape"(%243) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %245:3 = "cute.get_leaves"(%244) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %246 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %247 = "cute.slice"(%150, %246) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %248 = "cute.get_iter"(%247) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %249 = "cute.deref_arith_tuple_iter"(%248) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %250:2 = "cute.get_leaves"(%249) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %251 = "cute.get_scalars"(%250#0) : (!cute.int_tuple<"?">) -> i32
      %252 = "cute.get_scalars"(%250#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %253 = "cute.get_iter"(%247) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %254 = "cute.deref_arith_tuple_iter"(%253) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %255:2 = "cute.get_leaves"(%254) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %256 = "cute.get_scalars"(%255#0) : (!cute.int_tuple<"?">) -> i32
      %257 = "cute.get_scalars"(%255#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %258 = "cute.get_iter"(%247) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %259 = "cute.deref_arith_tuple_iter"(%258) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %260:2 = "cute.get_leaves"(%259) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %261 = "cute.get_scalars"(%260#0) : (!cute.int_tuple<"?">) -> i32
      %262 = "cute.get_scalars"(%260#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %263 = "cute.make_coord"(%260#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %264 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %265 = "cute.elem_less"(%263, %264) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %266 = "arith.extui"(%265) : (i1) -> i8
      %267 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%187, %267, %266) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %268 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %269 = "cute.get_shape"(%268) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %270:3 = "cute.get_leaves"(%269) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %271 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %272 = "cute.slice"(%150, %271) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %273 = "cute.get_iter"(%272) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %274 = "cute.deref_arith_tuple_iter"(%273) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %275:2 = "cute.get_leaves"(%274) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %276 = "cute.get_scalars"(%275#0) : (!cute.int_tuple<"?">) -> i32
      %277 = "cute.get_scalars"(%275#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %278 = "cute.get_iter"(%272) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %279 = "cute.deref_arith_tuple_iter"(%278) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %280:2 = "cute.get_leaves"(%279) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %281 = "cute.get_scalars"(%280#0) : (!cute.int_tuple<"?">) -> i32
      %282 = "cute.get_scalars"(%280#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %283 = "cute.get_iter"(%272) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %284 = "cute.deref_arith_tuple_iter"(%283) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %285:2 = "cute.get_leaves"(%284) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %286 = "cute.get_scalars"(%285#0) : (!cute.int_tuple<"?">) -> i32
      %287 = "cute.get_scalars"(%285#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %288 = "cute.make_coord"(%285#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %289 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %290 = "cute.elem_less"(%288, %289) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %291 = "arith.extui"(%290) : (i1) -> i8
      %292 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%187, %292, %291) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %293 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %294 = "cute.get_shape"(%293) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %295:3 = "cute.get_leaves"(%294) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %296 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %297 = "cute.slice"(%150, %296) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %298 = "cute.get_iter"(%297) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %299 = "cute.deref_arith_tuple_iter"(%298) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %300:2 = "cute.get_leaves"(%299) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %301 = "cute.get_scalars"(%300#0) : (!cute.int_tuple<"?">) -> i32
      %302 = "cute.get_scalars"(%300#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %303 = "cute.get_iter"(%297) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %304 = "cute.deref_arith_tuple_iter"(%303) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %305:2 = "cute.get_leaves"(%304) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %306 = "cute.get_scalars"(%305#0) : (!cute.int_tuple<"?">) -> i32
      %307 = "cute.get_scalars"(%305#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %308 = "cute.get_iter"(%297) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %309 = "cute.deref_arith_tuple_iter"(%308) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %310:2 = "cute.get_leaves"(%309) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %311 = "cute.get_scalars"(%310#0) : (!cute.int_tuple<"?">) -> i32
      %312 = "cute.get_scalars"(%310#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %313 = "cute.make_coord"(%310#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %314 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %315 = "cute.elem_less"(%313, %314) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %316 = "arith.extui"(%315) : (i1) -> i8
      %317 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%187, %317, %316) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %318 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %319 = "cute.get_shape"(%318) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %320:3 = "cute.get_leaves"(%319) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %321 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %322 = "cute.slice"(%150, %321) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %323 = "cute.get_iter"(%322) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %324 = "cute.deref_arith_tuple_iter"(%323) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %325:2 = "cute.get_leaves"(%324) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %326 = "cute.get_scalars"(%325#0) : (!cute.int_tuple<"?">) -> i32
      %327 = "cute.get_scalars"(%325#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %328 = "cute.get_iter"(%322) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %329 = "cute.deref_arith_tuple_iter"(%328) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %330:2 = "cute.get_leaves"(%329) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %331 = "cute.get_scalars"(%330#0) : (!cute.int_tuple<"?">) -> i32
      %332 = "cute.get_scalars"(%330#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %333 = "cute.get_iter"(%322) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %334 = "cute.deref_arith_tuple_iter"(%333) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %335:2 = "cute.get_leaves"(%334) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %336 = "cute.get_scalars"(%335#0) : (!cute.int_tuple<"?">) -> i32
      %337 = "cute.get_scalars"(%335#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %338 = "cute.make_coord"(%335#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %339 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %340 = "cute.elem_less"(%338, %339) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %341 = "arith.extui"(%340) : (i1) -> i8
      %342 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%187, %342, %341) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %343 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %344 = "cute.get_shape"(%343) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %345:3 = "cute.get_leaves"(%344) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %346 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %347 = "cute.slice"(%150, %346) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %348 = "cute.get_iter"(%347) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %349 = "cute.deref_arith_tuple_iter"(%348) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %350:2 = "cute.get_leaves"(%349) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %351 = "cute.get_scalars"(%350#0) : (!cute.int_tuple<"?">) -> i32
      %352 = "cute.get_scalars"(%350#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %353 = "cute.get_iter"(%347) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %354 = "cute.deref_arith_tuple_iter"(%353) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %355:2 = "cute.get_leaves"(%354) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %356 = "cute.get_scalars"(%355#0) : (!cute.int_tuple<"?">) -> i32
      %357 = "cute.get_scalars"(%355#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %358 = "cute.get_iter"(%347) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %359 = "cute.deref_arith_tuple_iter"(%358) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %360:2 = "cute.get_leaves"(%359) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %361 = "cute.get_scalars"(%360#0) : (!cute.int_tuple<"?">) -> i32
      %362 = "cute.get_scalars"(%360#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %363 = "cute.make_coord"(%360#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %364 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %365 = "cute.elem_less"(%363, %364) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %366 = "arith.extui"(%365) : (i1) -> i8
      %367 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%187, %367, %366) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %368 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %369 = "cute.get_shape"(%368) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %370:3 = "cute.get_leaves"(%369) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %371 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %372 = "cute.slice"(%150, %371) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %373 = "cute.get_iter"(%372) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %374 = "cute.deref_arith_tuple_iter"(%373) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %375:2 = "cute.get_leaves"(%374) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %376 = "cute.get_scalars"(%375#0) : (!cute.int_tuple<"?">) -> i32
      %377 = "cute.get_scalars"(%375#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %378 = "cute.get_iter"(%372) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %379 = "cute.deref_arith_tuple_iter"(%378) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %380:2 = "cute.get_leaves"(%379) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %381 = "cute.get_scalars"(%380#0) : (!cute.int_tuple<"?">) -> i32
      %382 = "cute.get_scalars"(%380#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %383 = "cute.get_iter"(%372) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %384 = "cute.deref_arith_tuple_iter"(%383) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %385:2 = "cute.get_leaves"(%384) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %386 = "cute.get_scalars"(%385#0) : (!cute.int_tuple<"?">) -> i32
      %387 = "cute.get_scalars"(%385#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %388 = "cute.make_coord"(%385#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %389 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %390 = "cute.elem_less"(%388, %389) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %391 = "arith.extui"(%390) : (i1) -> i8
      %392 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%187, %392, %391) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %393 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %394 = "cute.slice"(%150, %393) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %395 = "cute.get_iter"(%394) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %396 = "cute.deref_arith_tuple_iter"(%395) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %397:2 = "cute.get_leaves"(%396) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %398 = "cute.get_scalars"(%397#0) : (!cute.int_tuple<"?">) -> i32
      %399 = "cute.get_scalars"(%397#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %400 = "cute.get_iter"(%394) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %401 = "cute.deref_arith_tuple_iter"(%400) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %402:2 = "cute.get_leaves"(%401) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %403 = "cute.get_scalars"(%402#0) : (!cute.int_tuple<"?">) -> i32
      %404 = "cute.get_scalars"(%402#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %405 = "cute.get_iter"(%394) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %406 = "cute.deref_arith_tuple_iter"(%405) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %407:2 = "cute.get_leaves"(%406) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %408 = "cute.get_scalars"(%407#0) : (!cute.int_tuple<"?">) -> i32
      %409 = "cute.get_scalars"(%407#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %410 = "arith.cmpi"(%408, %58) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%410) ({
        %960 = "cute.get_layout"(%141) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %961 = "cute.get_shape"(%960) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %962:4 = "cute.get_leaves"(%961) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %963 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %964 = "cute.get_shape"(%963) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %965:4 = "cute.get_leaves"(%964) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %966 = "cute.get_layout"(%141) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %967 = "cute.make_shape"() : () -> !cute.shape<"1">
        %968 = "cute.make_layout"(%967) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %969 = "cute.append_to_rank"(%966, %968) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %970 = "cute.make_view"(%142, %969) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %971 = "cute.get_iter"(%970) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %972 = "cute.get_layout"(%970) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %973 = "cute.get_shape"(%972) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %974:4 = "cute.get_leaves"(%973) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %975 = "cute.get_layout"(%970) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %976 = "cute.get_shape"(%975) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %977:4 = "cute.get_leaves"(%976) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %978 = "cute.group_modes"(%970) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %979 = "cute.get_iter"(%978) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %980 = "cute.get_iter"(%978) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %981 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %982 = "cute.make_shape"() : () -> !cute.shape<"1">
        %983 = "cute.make_layout"(%982) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %984 = "cute.append_to_rank"(%981, %983) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %985 = "cute.make_view"(%145, %984) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_smem_bf16_1
        %986 = "cute.get_iter"(%985) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<16>>
        %987 = "cute.get_layout"(%985) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %988 = "cute.get_shape"(%987) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %989:4 = "cute.get_leaves"(%988) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %990 = "cute.get_layout"(%985) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %991 = "cute.get_shape"(%990) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %992:4 = "cute.get_leaves"(%991) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %993 = "cute.group_modes"(%985) <{begin = 1 : i32, end = 3 : i32}> : (!memref_smem_bf16_1) -> !memref_smem_bf16_2
        %994 = "cute.get_iter"(%993) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %995 = "cute.get_iter"(%993) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<16>>
        %996 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %997 = "cute.make_shape"() : () -> !cute.shape<"1">
        %998 = "cute.make_layout"(%997) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %999 = "cute.append_to_rank"(%996, %998) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1000 = "cute.make_view"(%189, %999) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %1001 = "cute.get_iter"(%1000) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1002 = "cute.get_layout"(%1000) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1003 = "cute.get_shape"(%1002) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1004:3 = "cute.get_leaves"(%1003) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1005 = "cute.get_layout"(%1000) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %1006 = "cute.get_shape"(%1005) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %1007:3 = "cute.get_leaves"(%1006) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1008 = "cute.group_modes"(%1000) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %1009 = "cute.get_iter"(%1008) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1010 = "cute.get_iter"(%1008) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1011 = "cute.get_layout"(%978) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1012 = "cute.get_shape"(%1011) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1013:4 = "cute.get_leaves"(%1012) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1014 = "cute.get_layout"(%993) : (!memref_smem_bf16_2) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %1015 = "cute.get_shape"(%1014) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %1016:4 = "cute.get_leaves"(%1015) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %1017 = "cute.size"(%978) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %1018 = "cute.get_leaves"(%1017) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %1019 = "cute.size"(%993) <{mode = array<i32: 1>}> : (!memref_smem_bf16_2) -> !cute.int_tuple<"1">
        %1020 = "cute.get_leaves"(%1019) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%131, %978, %993, %1008) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_6, !memref_smem_bf16_2, !memref_rmem_i8_1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %411 = "cute.make_coord"(%48) : (i32) -> !cute.coord<"?">
      %412 = "cute.tiled.copy.partition_S"(%137, %113, %411) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %413 = "cute.get_iter"(%412) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %414 = "cute.deref_arith_tuple_iter"(%413) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %415:2 = "cute.get_leaves"(%414) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %416 = "cute.get_scalars"(%415#0) : (!cute.int_tuple<"?">) -> i32
      %417 = "cute.get_scalars"(%415#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %418 = "cute.size"(%412) <{mode = array<i32: 0, 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %419 = "cute.get_leaves"(%418) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %420 = "cute.size"(%412) <{mode = array<i32: 1>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %421 = "cute.get_leaves"(%420) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %422 = "cute.size"(%412) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %423 = "cute.get_leaves"(%422) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %424 = "cute.size"(%412) <{mode = array<i32: 2>}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %425 = "cute.get_leaves"(%424) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %426 = "cute.make_shape"() : () -> !cute.shape<"(8,1,1)">
      %427 = "cute.make_stride"() : () -> !cute.stride<"(1,0,1)">
      %428 = "cute.make_layout"(%426, %427) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(8,1,1)">, !cute.stride<"(1,0,1)">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %429 = "cute.memref.alloca"(%428) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %430 = "cute.get_iter"(%429) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %431 = "cute.get_iter"(%429) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %432 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %433 = "cute.get_shape"(%432) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %434:3 = "cute.get_leaves"(%433) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %435 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %436 = "cute.get_shape"(%435) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %437:3 = "cute.get_leaves"(%436) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %438 = "cute.make_coord"() : () -> !cute.coord<"((0,0),0,0)">
      %439 = "cute.slice"(%412, %438) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %440 = "cute.get_iter"(%439) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %441 = "cute.deref_arith_tuple_iter"(%440) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %442:2 = "cute.get_leaves"(%441) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %443 = "cute.get_scalars"(%442#0) : (!cute.int_tuple<"?">) -> i32
      %444 = "cute.get_scalars"(%442#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %445 = "cute.get_iter"(%439) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %446 = "cute.deref_arith_tuple_iter"(%445) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %447:2 = "cute.get_leaves"(%446) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %448 = "cute.get_scalars"(%447#0) : (!cute.int_tuple<"?">) -> i32
      %449 = "cute.get_scalars"(%447#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %450 = "cute.get_iter"(%439) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %451 = "cute.deref_arith_tuple_iter"(%450) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %452:2 = "cute.get_leaves"(%451) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %453 = "cute.get_scalars"(%452#0) : (!cute.int_tuple<"?">) -> i32
      %454 = "cute.get_scalars"(%452#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %455 = "cute.make_coord"(%452#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %456 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %457 = "cute.elem_less"(%455, %456) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %458 = "arith.extui"(%457) : (i1) -> i8
      %459 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%429, %459, %458) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %460 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %461 = "cute.get_shape"(%460) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %462:3 = "cute.get_leaves"(%461) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %463 = "cute.make_coord"() : () -> !cute.coord<"((0,1),0,0)">
      %464 = "cute.slice"(%412, %463) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %465 = "cute.get_iter"(%464) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %466 = "cute.deref_arith_tuple_iter"(%465) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %467:2 = "cute.get_leaves"(%466) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %468 = "cute.get_scalars"(%467#0) : (!cute.int_tuple<"?">) -> i32
      %469 = "cute.get_scalars"(%467#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %470 = "cute.get_iter"(%464) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %471 = "cute.deref_arith_tuple_iter"(%470) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %472:2 = "cute.get_leaves"(%471) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %473 = "cute.get_scalars"(%472#0) : (!cute.int_tuple<"?">) -> i32
      %474 = "cute.get_scalars"(%472#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %475 = "cute.get_iter"(%464) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %476 = "cute.deref_arith_tuple_iter"(%475) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %477:2 = "cute.get_leaves"(%476) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %478 = "cute.get_scalars"(%477#0) : (!cute.int_tuple<"?">) -> i32
      %479 = "cute.get_scalars"(%477#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %480 = "cute.make_coord"(%477#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %481 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %482 = "cute.elem_less"(%480, %481) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %483 = "arith.extui"(%482) : (i1) -> i8
      %484 = "cute.make_coord"() : () -> !cute.coord<"(1,0,0)">
      "cute.memref.store"(%429, %484, %483) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %485 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %486 = "cute.get_shape"(%485) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %487:3 = "cute.get_leaves"(%486) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %488 = "cute.make_coord"() : () -> !cute.coord<"((0,2),0,0)">
      %489 = "cute.slice"(%412, %488) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %490 = "cute.get_iter"(%489) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %491 = "cute.deref_arith_tuple_iter"(%490) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %492:2 = "cute.get_leaves"(%491) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %493 = "cute.get_scalars"(%492#0) : (!cute.int_tuple<"?">) -> i32
      %494 = "cute.get_scalars"(%492#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %495 = "cute.get_iter"(%489) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %496 = "cute.deref_arith_tuple_iter"(%495) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %497:2 = "cute.get_leaves"(%496) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %498 = "cute.get_scalars"(%497#0) : (!cute.int_tuple<"?">) -> i32
      %499 = "cute.get_scalars"(%497#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %500 = "cute.get_iter"(%489) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %501 = "cute.deref_arith_tuple_iter"(%500) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %502:2 = "cute.get_leaves"(%501) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %503 = "cute.get_scalars"(%502#0) : (!cute.int_tuple<"?">) -> i32
      %504 = "cute.get_scalars"(%502#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %505 = "cute.make_coord"(%502#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %506 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %507 = "cute.elem_less"(%505, %506) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %508 = "arith.extui"(%507) : (i1) -> i8
      %509 = "cute.make_coord"() : () -> !cute.coord<"(2,0,0)">
      "cute.memref.store"(%429, %509, %508) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %510 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %511 = "cute.get_shape"(%510) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %512:3 = "cute.get_leaves"(%511) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %513 = "cute.make_coord"() : () -> !cute.coord<"((0,3),0,0)">
      %514 = "cute.slice"(%412, %513) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %515 = "cute.get_iter"(%514) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %516 = "cute.deref_arith_tuple_iter"(%515) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %517:2 = "cute.get_leaves"(%516) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %518 = "cute.get_scalars"(%517#0) : (!cute.int_tuple<"?">) -> i32
      %519 = "cute.get_scalars"(%517#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %520 = "cute.get_iter"(%514) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %521 = "cute.deref_arith_tuple_iter"(%520) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %522:2 = "cute.get_leaves"(%521) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %523 = "cute.get_scalars"(%522#0) : (!cute.int_tuple<"?">) -> i32
      %524 = "cute.get_scalars"(%522#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %525 = "cute.get_iter"(%514) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %526 = "cute.deref_arith_tuple_iter"(%525) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %527:2 = "cute.get_leaves"(%526) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %528 = "cute.get_scalars"(%527#0) : (!cute.int_tuple<"?">) -> i32
      %529 = "cute.get_scalars"(%527#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %530 = "cute.make_coord"(%527#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %531 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %532 = "cute.elem_less"(%530, %531) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %533 = "arith.extui"(%532) : (i1) -> i8
      %534 = "cute.make_coord"() : () -> !cute.coord<"(3,0,0)">
      "cute.memref.store"(%429, %534, %533) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %535 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %536 = "cute.get_shape"(%535) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %537:3 = "cute.get_leaves"(%536) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %538 = "cute.make_coord"() : () -> !cute.coord<"((0,4),0,0)">
      %539 = "cute.slice"(%412, %538) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %540 = "cute.get_iter"(%539) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %541 = "cute.deref_arith_tuple_iter"(%540) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %542:2 = "cute.get_leaves"(%541) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %543 = "cute.get_scalars"(%542#0) : (!cute.int_tuple<"?">) -> i32
      %544 = "cute.get_scalars"(%542#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %545 = "cute.get_iter"(%539) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %546 = "cute.deref_arith_tuple_iter"(%545) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %547:2 = "cute.get_leaves"(%546) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %548 = "cute.get_scalars"(%547#0) : (!cute.int_tuple<"?">) -> i32
      %549 = "cute.get_scalars"(%547#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %550 = "cute.get_iter"(%539) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %551 = "cute.deref_arith_tuple_iter"(%550) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %552:2 = "cute.get_leaves"(%551) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %553 = "cute.get_scalars"(%552#0) : (!cute.int_tuple<"?">) -> i32
      %554 = "cute.get_scalars"(%552#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %555 = "cute.make_coord"(%552#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %556 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %557 = "cute.elem_less"(%555, %556) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %558 = "arith.extui"(%557) : (i1) -> i8
      %559 = "cute.make_coord"() : () -> !cute.coord<"(4,0,0)">
      "cute.memref.store"(%429, %559, %558) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %560 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %561 = "cute.get_shape"(%560) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %562:3 = "cute.get_leaves"(%561) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %563 = "cute.make_coord"() : () -> !cute.coord<"((0,5),0,0)">
      %564 = "cute.slice"(%412, %563) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %565 = "cute.get_iter"(%564) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %566 = "cute.deref_arith_tuple_iter"(%565) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %567:2 = "cute.get_leaves"(%566) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %568 = "cute.get_scalars"(%567#0) : (!cute.int_tuple<"?">) -> i32
      %569 = "cute.get_scalars"(%567#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %570 = "cute.get_iter"(%564) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %571 = "cute.deref_arith_tuple_iter"(%570) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %572:2 = "cute.get_leaves"(%571) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %573 = "cute.get_scalars"(%572#0) : (!cute.int_tuple<"?">) -> i32
      %574 = "cute.get_scalars"(%572#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %575 = "cute.get_iter"(%564) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %576 = "cute.deref_arith_tuple_iter"(%575) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %577:2 = "cute.get_leaves"(%576) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %578 = "cute.get_scalars"(%577#0) : (!cute.int_tuple<"?">) -> i32
      %579 = "cute.get_scalars"(%577#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %580 = "cute.make_coord"(%577#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %581 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %582 = "cute.elem_less"(%580, %581) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %583 = "arith.extui"(%582) : (i1) -> i8
      %584 = "cute.make_coord"() : () -> !cute.coord<"(5,0,0)">
      "cute.memref.store"(%429, %584, %583) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %585 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %586 = "cute.get_shape"(%585) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %587:3 = "cute.get_leaves"(%586) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %588 = "cute.make_coord"() : () -> !cute.coord<"((0,6),0,0)">
      %589 = "cute.slice"(%412, %588) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %590 = "cute.get_iter"(%589) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %591 = "cute.deref_arith_tuple_iter"(%590) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %592:2 = "cute.get_leaves"(%591) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %593 = "cute.get_scalars"(%592#0) : (!cute.int_tuple<"?">) -> i32
      %594 = "cute.get_scalars"(%592#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %595 = "cute.get_iter"(%589) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %596 = "cute.deref_arith_tuple_iter"(%595) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %597:2 = "cute.get_leaves"(%596) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %598 = "cute.get_scalars"(%597#0) : (!cute.int_tuple<"?">) -> i32
      %599 = "cute.get_scalars"(%597#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %600 = "cute.get_iter"(%589) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %601 = "cute.deref_arith_tuple_iter"(%600) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %602:2 = "cute.get_leaves"(%601) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %603 = "cute.get_scalars"(%602#0) : (!cute.int_tuple<"?">) -> i32
      %604 = "cute.get_scalars"(%602#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %605 = "cute.make_coord"(%602#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %606 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %607 = "cute.elem_less"(%605, %606) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %608 = "arith.extui"(%607) : (i1) -> i8
      %609 = "cute.make_coord"() : () -> !cute.coord<"(6,0,0)">
      "cute.memref.store"(%429, %609, %608) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %610 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %611 = "cute.get_shape"(%610) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %612:3 = "cute.get_leaves"(%611) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %613 = "cute.make_coord"() : () -> !cute.coord<"((0,7),0,0)">
      %614 = "cute.slice"(%412, %613) : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">) -> !cute.coord_tensor<"(?,?{div=8})", "():()">
      %615 = "cute.get_iter"(%614) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %616 = "cute.deref_arith_tuple_iter"(%615) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %617:2 = "cute.get_leaves"(%616) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %618 = "cute.get_scalars"(%617#0) : (!cute.int_tuple<"?">) -> i32
      %619 = "cute.get_scalars"(%617#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %620 = "cute.get_iter"(%614) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %621 = "cute.deref_arith_tuple_iter"(%620) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %622:2 = "cute.get_leaves"(%621) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %623 = "cute.get_scalars"(%622#0) : (!cute.int_tuple<"?">) -> i32
      %624 = "cute.get_scalars"(%622#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %625 = "cute.get_iter"(%614) : (!cute.coord_tensor<"(?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %626 = "cute.deref_arith_tuple_iter"(%625) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %627:2 = "cute.get_leaves"(%626) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %628 = "cute.get_scalars"(%627#0) : (!cute.int_tuple<"?">) -> i32
      %629 = "cute.get_scalars"(%627#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %630 = "cute.make_coord"(%627#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %631 = "cute.make_coord"() : () -> !cute.coord<"4096">
      %632 = "cute.elem_less"(%630, %631) : (!cute.coord<"?{div=8}">, !cute.coord<"4096">) -> i1
      %633 = "arith.extui"(%632) : (i1) -> i8
      %634 = "cute.make_coord"() : () -> !cute.coord<"(7,0,0)">
      "cute.memref.store"(%429, %634, %633) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %635 = "cute.get_layout"(%167) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %636 = "cute.get_shape"(%635) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %637:4 = "cute.get_leaves"(%636) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %638 = "cute.get_layout"(%171) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %639 = "cute.get_shape"(%638) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %640:4 = "cute.get_leaves"(%639) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %641 = "cute.get_layout"(%167) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %642 = "cute.make_shape"() : () -> !cute.shape<"1">
      %643 = "cute.make_layout"(%642) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %644 = "cute.append_to_rank"(%641, %643) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %645 = "cute.make_view"(%168, %644) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
      %646 = "cute.get_iter"(%645) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
      %647 = "cute.get_layout"(%645) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %648 = "cute.get_shape"(%647) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %649:4 = "cute.get_leaves"(%648) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %650 = "cute.get_layout"(%645) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %651 = "cute.get_shape"(%650) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %652:4 = "cute.get_leaves"(%651) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %653 = "cute.group_modes"(%645) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
      %654 = "cute.get_iter"(%653) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %655 = "cute.get_iter"(%653) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
      %656 = "cute.get_layout"(%171) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %657 = "cute.make_shape"() : () -> !cute.shape<"1">
      %658 = "cute.make_layout"(%657) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %659 = "cute.append_to_rank"(%656, %658) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %660 = "cute.make_view"(%173, %659) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
      %661 = "cute.get_iter"(%660) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %662 = "cute.get_layout"(%660) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %663 = "cute.get_shape"(%662) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %664:4 = "cute.get_leaves"(%663) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %665 = "cute.get_layout"(%660) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %666 = "cute.get_shape"(%665) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %667:4 = "cute.get_leaves"(%666) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %668 = "cute.group_modes"(%660) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
      %669 = "cute.get_iter"(%668) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %670 = "cute.get_iter"(%668) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
      %671 = "cute.get_layout"(%429) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %672 = "cute.make_shape"() : () -> !cute.shape<"1">
      %673 = "cute.make_layout"(%672) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %674 = "cute.append_to_rank"(%671, %673) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
      %675 = "cute.make_view"(%431, %674) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
      %676 = "cute.get_iter"(%675) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %677 = "cute.get_layout"(%675) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %678 = "cute.get_shape"(%677) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %679:3 = "cute.get_leaves"(%678) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %680 = "cute.get_layout"(%675) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
      %681 = "cute.get_shape"(%680) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %682:3 = "cute.get_leaves"(%681) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %683 = "cute.group_modes"(%675) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %684 = "cute.get_iter"(%683) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %685 = "cute.get_iter"(%683) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %686 = "cute.get_layout"(%653) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
      %687 = "cute.get_shape"(%686) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %688:4 = "cute.get_leaves"(%687) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %689 = "cute.get_layout"(%668) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
      %690 = "cute.get_shape"(%689) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %691:4 = "cute.get_leaves"(%690) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %692 = "cute.size"(%653) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
      %693 = "cute.get_leaves"(%692) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %694 = "cute.size"(%668) <{mode = array<i32: 1>}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
      %695 = "cute.get_leaves"(%694) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%132, %653, %668, %683) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_6, !memref_rmem_bf16_1, !memref_rmem_i8_1) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %696 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %697 = "cute.get_shape"(%696) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %698:4 = "cute.get_leaves"(%697) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %699 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %700 = "cute.get_shape"(%699) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %701:4 = "cute.get_leaves"(%700) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %702 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %703 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %704 = "cute.right_inverse"(%703) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %705 = "cute.composition"(%702, %704) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %706 = "cute.coalesce"(%705) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %707 = "cute.get_shape"(%706) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %708:2 = "cute.get_leaves"(%707) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %709 = "cute.get_stride"(%706) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %710:2 = "cute.get_leaves"(%709) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %711 = "cute.get_shape"(%706) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %712:2 = "cute.get_leaves"(%711) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %713 = "cute.get_shape"(%706) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %714:2 = "cute.get_leaves"(%713) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %715 = "cute.get"(%706) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %716 = "cute.composition"(%704, %715) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %717 = "cute.size"(%716) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %718 = "cute.get_leaves"(%717) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %719 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %720 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %721 = "cute.logical_divide"(%144, %716) : (!memref_smem_bf16_1, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %722 = "cute.get_iter"(%721) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %723 = "cute.get_iter"(%721) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %724 = "cute.logical_divide"(%158, %716) : (!memref_rmem_bf16_, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %725 = "cute.get_iter"(%724) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %726 = "cute.get_iter"(%724) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %727 = "cute.make_shape"() : () -> !cute.shape<"8">
      %728 = "cute.make_layout"(%727) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %729 = "cute.logical_divide"(%721, %728) : (!memref_smem_bf16_3, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %730 = "cute.get_iter"(%729) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %731 = "cute.get_iter"(%729) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %732 = "cute.make_shape"() : () -> !cute.shape<"8">
      %733 = "cute.make_layout"(%732) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %734 = "cute.logical_divide"(%724, %733) : (!memref_rmem_bf16_2, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %735 = "cute.get_iter"(%734) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %736 = "cute.get_iter"(%734) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %737 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      "cute.copy"(%737, %729, %734) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2) -> ()
      %738 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %739 = "cute.get_shape"(%738) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %740:4 = "cute.get_leaves"(%739) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %741 = "cute.memref.load_vec"(%158) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %742 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %743 = "cute.get_shape"(%742) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %744:4 = "cute.get_leaves"(%743) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %745 = "arith.extf"(%741) : (vector<64xbf16>) -> vector<64xf32>
      %746 = "arith.mulf"(%745, %745) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %747 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %748 = "vector.reduction"(%746, %747) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %749 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %750 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %751 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %752 = "nvvm.shfl.sync"(%749, %748, %750, %751) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %753 = "arith.addf"(%752, %748) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %754 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %755 = "nvvm.shfl.sync"(%749, %753, %754, %751) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %756 = "arith.addf"(%753, %755) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %757 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %758 = "nvvm.shfl.sync"(%749, %756, %757, %751) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %759 = "arith.addf"(%756, %758) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %760 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %761 = "nvvm.shfl.sync"(%749, %759, %760, %751) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %762 = "arith.addf"(%759, %761) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %763 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %764 = "nvvm.shfl.sync"(%749, %762, %763, %751) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %765 = "arith.addf"(%762, %764) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %766 = "nvvm.read.ptx.sreg.laneid"() : () -> i32
      %767 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %768 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %769 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %770 = "nvvm.read.ptx.sreg.ntid.x"() : () -> i32
      %771 = "nvvm.read.ptx.sreg.ntid.y"() : () -> i32
      %772 = "arith.muli"(%768, %770) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %773 = "arith.addi"(%767, %772) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %774 = "arith.muli"(%769, %770) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %775 = "arith.muli"(%774, %771) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %776 = "arith.addi"(%773, %775) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %777 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %778 = "arith.floordivsi"(%776, %777) : (i32, i32) -> i32
      %779 = "cute.get_layout"(%91) : (!memref_smem_f32_) -> !cute.layout<"(2,2):(1,2)">
      %780 = "cute.get_shape"(%779) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %781:2 = "cute.get_leaves"(%780) : (!cute.shape<"(2,2)">) -> (!cute.shape<"2">, !cute.shape<"2">)
      %782 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
      %783 = "cute.size"(%782) <{mode = array<i32>}> : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %784 = "cute.get_leaves"(%783) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %785 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %786 = "arith.floordivsi"(%778, %785) : (i32, i32) -> i32
      %787 = "arith.remsi"(%778, %785) : (i32, i32) -> i32
      %788 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %789 = "arith.cmpi"(%766, %788) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %790 = "scf.if"(%789) ({
        %958 = "cute.get_iter"(%91) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        %959 = "cute.make_coord"(%786, %787) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%91, %959, %765) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"(%91) : (!memref_smem_f32_) -> ()
      }, {
        %957 = "cute.get_iter"(%91) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
        "scf.yield"(%91) : (!memref_smem_f32_) -> ()
      }) : (i1) -> !memref_smem_f32_
      %791 = "cute.get_iter"(%790) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %792 = "cute.get_iter"(%790) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %793 = "cute.get_iter"(%790) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %794 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%794) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %795 = "arith.cmpi"(%766, %785) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %796 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %797 = "scf.if"(%795) ({
        %955 = "cute.make_coord"(%786, %766) : (i32, i32) -> !cute.coord<"(?,?)">
        %956 = "cute.memref.load"(%790, %955) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%956) : (f32) -> ()
      }, {
        "scf.yield"(%796) : (f32) -> ()
      }) : (i1) -> f32
      %798 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %799 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %800 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %801 = "nvvm.shfl.sync"(%798, %797, %799, %800) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %802 = "arith.addf"(%797, %801) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %803 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %804 = "nvvm.shfl.sync"(%798, %802, %803, %800) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %805 = "arith.addf"(%802, %804) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %806 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %807 = "nvvm.shfl.sync"(%798, %805, %806, %800) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %808 = "arith.addf"(%805, %807) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %809 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %810 = "nvvm.shfl.sync"(%798, %808, %809, %800) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %811 = "arith.addf"(%808, %810) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %812 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %813 = "nvvm.shfl.sync"(%798, %811, %812, %800) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %814 = "arith.addf"(%811, %813) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %815 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %816 = "arith.divf"(%814, %815) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %817 = "arith.addf"(%816, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %818 = "math.rsqrt"(%817) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      %819 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      "llvm.inline_asm"(%819) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %820 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %821 = "cute.get_shape"(%820) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %822:4 = "cute.get_leaves"(%821) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %823 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %824 = "cute.get_shape"(%823) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %825:4 = "cute.get_leaves"(%824) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %826 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %827 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %828 = "cute.right_inverse"(%827) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %829 = "cute.composition"(%826, %828) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %830 = "cute.coalesce"(%829) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %831 = "cute.get_shape"(%830) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %832:2 = "cute.get_leaves"(%831) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %833 = "cute.get_stride"(%830) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %834:2 = "cute.get_leaves"(%833) : (!cute.stride<"(1,512)">) -> (!cute.stride<"1">, !cute.stride<"512">)
      %835 = "cute.get_shape"(%830) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %836:2 = "cute.get_leaves"(%835) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %837 = "cute.get_shape"(%830) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %838:2 = "cute.get_leaves"(%837) : (!cute.shape<"(8,8)">) -> (!cute.shape<"8">, !cute.shape<"8">)
      %839 = "cute.get"(%830) <{mode = array<i32: 0>}> : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"8:1">
      %840 = "cute.composition"(%828, %839) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %841 = "cute.size"(%840) <{mode = array<i32>}> : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %842 = "cute.get_leaves"(%841) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
      %843 = "cute.get_layout"(%144) : (!memref_smem_bf16_1) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %844 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %845 = "cute.logical_divide"(%144, %840) : (!memref_smem_bf16_1, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %846 = "cute.get_iter"(%845) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %847 = "cute.get_iter"(%845) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %848 = "cute.logical_divide"(%158, %840) : (!memref_rmem_bf16_, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %849 = "cute.get_iter"(%848) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %850 = "cute.get_iter"(%848) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %851 = "cute.make_shape"() : () -> !cute.shape<"8">
      %852 = "cute.make_layout"(%851) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %853 = "cute.logical_divide"(%845, %852) : (!memref_smem_bf16_3, !cute.layout<"8:1">) -> !memref_smem_bf16_3
      %854 = "cute.get_iter"(%853) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %855 = "cute.get_iter"(%853) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
      %856 = "cute.make_shape"() : () -> !cute.shape<"8">
      %857 = "cute.make_layout"(%856) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
      %858 = "cute.logical_divide"(%848, %857) : (!memref_rmem_bf16_2, !cute.layout<"8:1">) -> !memref_rmem_bf16_2
      %859 = "cute.get_iter"(%858) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %860 = "cute.get_iter"(%858) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<32>>
      %861 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      "cute.copy"(%861, %853, %858) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2) -> ()
      %862 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %863 = "cute.get_shape"(%862) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %864:4 = "cute.get_leaves"(%863) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %865 = "cute.memref.load_vec"(%158) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %866 = "cute.get_layout"(%158) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %867 = "cute.get_shape"(%866) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %868:4 = "cute.get_leaves"(%867) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %869 = "arith.extf"(%865) : (vector<64xbf16>) -> vector<64xf32>
      %870 = "vector.broadcast"(%818) : (f32) -> vector<64xf32>
      %871 = "arith.mulf"(%869, %870) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %872 = "cute.get_layout"(%174) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %873 = "cute.get_shape"(%872) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %874:4 = "cute.get_leaves"(%873) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %875 = "cute.memref.load_vec"(%174) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %876 = "cute.get_layout"(%174) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %877 = "cute.get_shape"(%876) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %878:4 = "cute.get_leaves"(%877) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %879 = "arith.extf"(%875) : (vector<64xbf16>) -> vector<64xf32>
      %880 = "arith.mulf"(%871, %879) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %881 = "arith.truncf"(%880) : (vector<64xf32>) -> vector<64xbf16>
      %882 = "cute.get_layout"(%163) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %883 = "cute.get_shape"(%882) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %884:4 = "cute.get_leaves"(%883) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %885 = "cute.get_layout"(%163) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %886 = "cute.get_shape"(%885) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %887:4 = "cute.get_leaves"(%886) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
      %888 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %889 = "cute.size"(%888) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %890 = "cute.get_leaves"(%889) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      %891 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((8,8),1,1)">
      %892 = "cute.size"(%891) <{mode = array<i32>}> : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %893 = "cute.get_leaves"(%892) : (!cute.int_tuple<"64">) -> !cute.int_tuple<"64">
      "cute.memref.store_vec"(%881, %163) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%410) ({
        %894 = "cute.get_layout"(%163) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %895 = "cute.get_shape"(%894) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %896:4 = "cute.get_leaves"(%895) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %897 = "cute.get_layout"(%147) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %898 = "cute.get_shape"(%897) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %899:4 = "cute.get_leaves"(%898) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %900 = "cute.get_layout"(%163) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %901 = "cute.make_shape"() : () -> !cute.shape<"1">
        %902 = "cute.make_layout"(%901) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %903 = "cute.append_to_rank"(%900, %902) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %904 = "cute.make_view"(%165, %903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !memref_rmem_bf16_
        %905 = "cute.get_iter"(%904) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
        %906 = "cute.get_layout"(%904) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %907 = "cute.get_shape"(%906) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %908:4 = "cute.get_leaves"(%907) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %909 = "cute.get_layout"(%904) : (!memref_rmem_bf16_) -> !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %910 = "cute.get_shape"(%909) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %911:4 = "cute.get_leaves"(%910) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %912 = "cute.group_modes"(%904) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
        %913 = "cute.get_iter"(%912) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %914 = "cute.get_iter"(%912) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<32>>
        %915 = "cute.get_layout"(%147) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %916 = "cute.make_shape"() : () -> !cute.shape<"1">
        %917 = "cute.make_layout"(%916) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %918 = "cute.append_to_rank"(%915, %917) <{rank = 2 : si32}> : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %919 = "cute.make_view"(%148, %918) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !memref_gmem_bf16_5
        %920 = "cute.get_iter"(%919) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %921 = "cute.get_layout"(%919) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %922 = "cute.get_shape"(%921) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %923:4 = "cute.get_leaves"(%922) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %924 = "cute.get_layout"(%919) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %925 = "cute.get_shape"(%924) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %926:4 = "cute.get_leaves"(%925) : (!cute.shape<"((8,8),1,1)">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %927 = "cute.group_modes"(%919) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %928 = "cute.get_iter"(%927) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %929 = "cute.get_iter"(%927) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %930 = "cute.get_layout"(%187) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %931 = "cute.make_shape"() : () -> !cute.shape<"1">
        %932 = "cute.make_layout"(%931) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %933 = "cute.append_to_rank"(%930, %932) <{rank = 2 : si32}> : (!cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1,1):(1,0,1)">
        %934 = "cute.make_view"(%189, %933) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8,1,1):(1,0,1)">) -> !memref_rmem_i8_
        %935 = "cute.get_iter"(%934) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %936 = "cute.get_layout"(%934) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %937 = "cute.get_shape"(%936) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %938:3 = "cute.get_leaves"(%937) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %939 = "cute.get_layout"(%934) : (!memref_rmem_i8_) -> !cute.layout<"(8,1,1):(1,0,1)">
        %940 = "cute.get_shape"(%939) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %941:3 = "cute.get_leaves"(%940) : (!cute.shape<"(8,1,1)">) -> (!cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %942 = "cute.group_modes"(%934) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %943 = "cute.get_iter"(%942) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %944 = "cute.get_iter"(%942) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %945 = "cute.get_layout"(%912) : (!memref_rmem_bf16_1) -> !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">
        %946 = "cute.get_shape"(%945) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %947:4 = "cute.get_leaves"(%946) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %948 = "cute.get_layout"(%927) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">
        %949 = "cute.get_shape"(%948) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %950:4 = "cute.get_leaves"(%949) : (!cute.shape<"((8,8),(1,1))">) -> (!cute.shape<"8">, !cute.shape<"8">, !cute.shape<"1">, !cute.shape<"1">)
        %951 = "cute.size"(%912) <{mode = array<i32: 1>}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
        %952 = "cute.get_leaves"(%951) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %953 = "cute.size"(%927) <{mode = array<i32: 1>}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %954 = "cute.get_leaves"(%953) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%133, %912, %927, %942) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_1, !memref_gmem_bf16_6, !memref_rmem_i8_1) -> ()
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
    %33 = "cuda.launch_ex"(%30, %3, %13, %8, %arg4, %17) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32, !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cuda.result
    %34 = "cuda.cast"(%33) : (!cuda.result) -> i32
    "cuda.return_if_error"(%34) : (i32) -> ()
    %35 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%35) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
