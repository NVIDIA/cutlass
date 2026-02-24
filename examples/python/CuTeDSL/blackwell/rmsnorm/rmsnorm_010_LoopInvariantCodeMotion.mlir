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
      %21 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %22 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %23 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %24 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %25 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %26 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %27 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %28 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(8))">
      %29 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(512))">
      %30 = "cute.static"() : () -> !cute.int_tuple<"56">
      %31 = "cute.static"() : () -> !cute.int_tuple<"48">
      %32 = "cute.static"() : () -> !cute.int_tuple<"40">
      %33 = "cute.static"() : () -> !cute.int_tuple<"32">
      %34 = "cute.static"() : () -> !cute.int_tuple<"24">
      %35 = "cute.static"() : () -> !cute.int_tuple<"16">
      %36 = "cute.static"() : () -> !cute.int_tuple<"8">
      %37 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %38 = "cute.static"() : () -> !cute.int_tuple<"7">
      %39 = "cute.static"() : () -> !cute.int_tuple<"3584">
      %40 = "cute.static"() : () -> !cute.int_tuple<"6">
      %41 = "cute.static"() : () -> !cute.int_tuple<"3072">
      %42 = "cute.static"() : () -> !cute.int_tuple<"5">
      %43 = "cute.static"() : () -> !cute.int_tuple<"2560">
      %44 = "cute.static"() : () -> !cute.int_tuple<"4">
      %45 = "cute.static"() : () -> !cute.int_tuple<"2048">
      %46 = "cute.static"() : () -> !cute.int_tuple<"3">
      %47 = "cute.static"() : () -> !cute.int_tuple<"1536">
      %48 = "cute.static"() : () -> !cute.int_tuple<"2">
      %49 = "cute.static"() : () -> !cute.int_tuple<"1024">
      %50 = "cute.static"() : () -> !cute.int_tuple<"512">
      %51 = "cute.static"() : () -> !cute.layout<"(8):(1)">
      %52 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %53 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %54 = "cute.static"() : () -> !cute.int_tuple<"1">
      %55 = "cute.static"() : () -> !cute.coord<"(7,0,0)">
      %56 = "cute.static"() : () -> !cute.int_tuple<"(0,3584)">
      %57 = "cute.static"() : () -> !cute.coord<"(6,0,0)">
      %58 = "cute.static"() : () -> !cute.int_tuple<"(0,3072)">
      %59 = "cute.static"() : () -> !cute.coord<"(5,0,0)">
      %60 = "cute.static"() : () -> !cute.int_tuple<"(0,2560)">
      %61 = "cute.static"() : () -> !cute.coord<"(4,0,0)">
      %62 = "cute.static"() : () -> !cute.int_tuple<"(0,2048)">
      %63 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
      %64 = "cute.static"() : () -> !cute.int_tuple<"(0,1536)">
      %65 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
      %66 = "cute.static"() : () -> !cute.int_tuple<"(0,1024)">
      %67 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
      %68 = "cute.static"() : () -> !cute.int_tuple<"(0,512)">
      %69 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      %70 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %71 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %72 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %73 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %74 = "cute.static"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %75 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %76 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %77 = "cute.static"() : () -> !cute.layout<"(2,2):(1,2)">
      %78 = "cute.static"() : () -> !cute.int_tuple<"16384">
      %79 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %80 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %81 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %82 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %83 = "cute.get_shape"(%82) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %84:2 = "cute.get_leaves"(%83) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %85 = "cute.to_int_tuple"(%84#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %86 = "cute.get_scalars"(%85) : (!cute.int_tuple<"?">) -> i32
      %87 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %88 = "cute.add_offset"(%87, %78) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %89 = "cute.recast_iter"(%87) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %90 = "cute.recast_iter"(%88) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %91 = "cute.make_view"(%90, %77) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %92 = "cute.make_shape"(%85) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %93 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %94 = "cute.make_layout"(%92, %76) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %95 = "cute.make_coord"(%81) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %96 = "cute.get_scalars"(%82) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %97 = "arith.ceildivsi"(%96, %75) : (i32, i32) -> i32
      %98 = "cute.make_shape"(%97) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %99 = "cute.make_layout"(%98, %74) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %100 = "cute.crd2idx"(%95, %99) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %101 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %102 = "cute.add_offset"(%101, %100) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %103 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %104 = "cute.get_scalars"(%103) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %105 = "arith.ceildivsi"(%104, %75) : (i32, i32) -> i32
      %106 = "cute.make_shape"(%105) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %107 = "cute.make_layout"(%106, %74) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %108 = "cute.crd2idx"(%95, %107) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %109 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %110 = "cute.add_offset"(%109, %108) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %111 = "cute.get_scalars"(%94) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %112 = "arith.ceildivsi"(%111, %75) : (i32, i32) -> i32
      %113 = "cute.make_shape"(%112) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %114 = "cute.make_layout"(%113, %73) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %115 = "cute.crd2idx"(%95, %114) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %116 = "cute.add_offset"(%93, %115) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %117 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %118 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %119 = "cute.make_tiled_copy"(%117) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %120 = "cute.make_tiled_copy"(%118) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %121 = "cute.make_tiled_copy"(%118) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %122 = "arith.divsi"(%80, %72) : (i32, i32) -> i32
      %123 = "arith.remsi"(%80, %72) : (i32, i32) -> i32
      %124 = "arith.muli"(%123, %71) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %125 = "arith.muli"(%122, %70) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %126 = "arith.addi"(%124, %125) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %127 = "cute.assume"(%126) : (i32) -> !cute.i32<divby 8>
      %128 = "cute.make_int_tuple"(%127) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %129 = "cute.add_offset"(%102, %128) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %130 = "cute.add_offset"(%89, %128) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %131 = "cute.add_offset"(%110, %128) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %132 = "cute.assume"(%124) : (i32) -> !cute.i32<divby 8>
      %133 = "cute.make_int_tuple"(%122, %132) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %134 = "cute.add_offset"(%116, %133) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %135 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %136 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %137 = "cute.get_iter"(%136) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %138 = "cute.make_int_tuple"(%132) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %139 = "cute.add_offset"(%79, %138) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %140 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %141 = "cute.get_iter"(%140) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %142 = "cute.make_view"(%141) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_
      %143 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %144 = "cute.get_iter"(%143) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %145 = "cute.deref_arith_tuple_iter"(%134) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %146:2 = "cute.get_leaves"(%145) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %147 = "cute.make_coord"(%146#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %148 = "cute.get_scalars"(%147) : (!cute.coord<"?{div=8}">) -> i32
      %149 = "arith.cmpi"(%148, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %150 = "arith.extui"(%149) : (i1) -> i8
      "cute.memref.store"(%143, %69, %150) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %151 = "cute.add_offset"(%134, %68) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %152 = "cute.deref_arith_tuple_iter"(%151) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %153:2 = "cute.get_leaves"(%152) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %154 = "cute.make_coord"(%153#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %155 = "cute.get_scalars"(%154) : (!cute.coord<"?{div=8}">) -> i32
      %156 = "arith.cmpi"(%155, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %157 = "arith.extui"(%156) : (i1) -> i8
      "cute.memref.store"(%143, %67, %157) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %158 = "cute.add_offset"(%134, %66) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %159 = "cute.deref_arith_tuple_iter"(%158) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %160:2 = "cute.get_leaves"(%159) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %161 = "cute.make_coord"(%160#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %162 = "cute.get_scalars"(%161) : (!cute.coord<"?{div=8}">) -> i32
      %163 = "arith.cmpi"(%162, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %164 = "arith.extui"(%163) : (i1) -> i8
      "cute.memref.store"(%143, %65, %164) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %165 = "cute.add_offset"(%134, %64) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %166 = "cute.deref_arith_tuple_iter"(%165) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %167:2 = "cute.get_leaves"(%166) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %168 = "cute.make_coord"(%167#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %169 = "cute.get_scalars"(%168) : (!cute.coord<"?{div=8}">) -> i32
      %170 = "arith.cmpi"(%169, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %171 = "arith.extui"(%170) : (i1) -> i8
      "cute.memref.store"(%143, %63, %171) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %172 = "cute.add_offset"(%134, %62) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %173 = "cute.deref_arith_tuple_iter"(%172) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %174:2 = "cute.get_leaves"(%173) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %175 = "cute.make_coord"(%174#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %176 = "cute.get_scalars"(%175) : (!cute.coord<"?{div=8}">) -> i32
      %177 = "arith.cmpi"(%176, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %178 = "arith.extui"(%177) : (i1) -> i8
      "cute.memref.store"(%143, %61, %178) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %179 = "cute.add_offset"(%134, %60) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %180 = "cute.deref_arith_tuple_iter"(%179) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %181:2 = "cute.get_leaves"(%180) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %182 = "cute.make_coord"(%181#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %183 = "cute.get_scalars"(%182) : (!cute.coord<"?{div=8}">) -> i32
      %184 = "arith.cmpi"(%183, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %185 = "arith.extui"(%184) : (i1) -> i8
      "cute.memref.store"(%143, %59, %185) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %186 = "cute.add_offset"(%134, %58) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %187 = "cute.deref_arith_tuple_iter"(%186) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %188:2 = "cute.get_leaves"(%187) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %189 = "cute.make_coord"(%188#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %190 = "cute.get_scalars"(%189) : (!cute.coord<"?{div=8}">) -> i32
      %191 = "arith.cmpi"(%190, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %192 = "arith.extui"(%191) : (i1) -> i8
      "cute.memref.store"(%143, %57, %192) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %193 = "cute.add_offset"(%134, %56) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %194 = "cute.deref_arith_tuple_iter"(%193) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %195:2 = "cute.get_leaves"(%194) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %196 = "cute.make_coord"(%195#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %197 = "cute.get_scalars"(%196) : (!cute.coord<"?{div=8}">) -> i32
      %198 = "arith.cmpi"(%197, %70) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %199 = "arith.extui"(%198) : (i1) -> i8
      "cute.memref.store"(%143, %55, %199) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %200 = "cute.get_scalars"(%146#0) : (!cute.int_tuple<"?">) -> i32
      %201 = "arith.cmpi"(%200, %86) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%201) ({
        %425 = "cute.make_view"(%144, %51) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_1
        %426 = "cute.derefine"(%425) : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %427 = "cute.get_iter"(%426) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
        %428 = "builtin.unrealized_conversion_cast"(%427) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %429 = "llvm.load"(%428) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %430 = "llvm.trunc"(%429) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %431 = "cute.recast_iter"(%129) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %432 = "cute.recast_iter"(%130) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%432, %431, %430) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %433 = "cute.add_offset"(%129, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
        %434 = "cute.add_offset"(%130, %50) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
        %435 = "cute.add_offset"(%427, %54) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %436 = "builtin.unrealized_conversion_cast"(%435) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %437 = "llvm.load"(%436) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %438 = "llvm.trunc"(%437) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %439 = "cute.recast_iter"(%433) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %440 = "cute.recast_iter"(%434) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%440, %439, %438) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %441 = "cute.add_offset"(%129, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
        %442 = "cute.add_offset"(%130, %49) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %443 = "cute.add_offset"(%427, %48) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %444 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %445 = "llvm.load"(%444) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %446 = "llvm.trunc"(%445) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %447 = "cute.recast_iter"(%441) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %448 = "cute.recast_iter"(%442) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%448, %447, %446) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %449 = "cute.add_offset"(%129, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
        %450 = "cute.add_offset"(%130, %47) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
        %451 = "cute.add_offset"(%427, %46) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %452 = "builtin.unrealized_conversion_cast"(%451) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %453 = "llvm.load"(%452) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %454 = "llvm.trunc"(%453) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %455 = "cute.recast_iter"(%449) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %456 = "cute.recast_iter"(%450) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%456, %455, %454) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %457 = "cute.add_offset"(%129, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
        %458 = "cute.add_offset"(%130, %45) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %459 = "cute.add_offset"(%427, %44) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %460 = "builtin.unrealized_conversion_cast"(%459) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %461 = "llvm.load"(%460) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %462 = "llvm.trunc"(%461) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %463 = "cute.recast_iter"(%457) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %464 = "cute.recast_iter"(%458) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%464, %463, %462) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %465 = "cute.add_offset"(%129, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
        %466 = "cute.add_offset"(%130, %43) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
        %467 = "cute.add_offset"(%427, %42) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %468 = "builtin.unrealized_conversion_cast"(%467) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %469 = "llvm.load"(%468) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %470 = "llvm.trunc"(%469) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %471 = "cute.recast_iter"(%465) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %472 = "cute.recast_iter"(%466) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%472, %471, %470) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %473 = "cute.add_offset"(%129, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
        %474 = "cute.add_offset"(%130, %41) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %475 = "cute.add_offset"(%427, %40) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %476 = "builtin.unrealized_conversion_cast"(%475) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %477 = "llvm.load"(%476) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %478 = "llvm.trunc"(%477) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %479 = "cute.recast_iter"(%473) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %480 = "cute.recast_iter"(%474) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%480, %479, %478) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %481 = "cute.add_offset"(%129, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
        %482 = "cute.add_offset"(%130, %39) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
        %483 = "cute.add_offset"(%427, %38) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %484 = "builtin.unrealized_conversion_cast"(%483) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %485 = "llvm.load"(%484) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %486 = "llvm.trunc"(%485) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %487 = "cute.recast_iter"(%481) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %488 = "cute.recast_iter"(%482) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%488, %487, %486) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %202 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %203 = "cute.get_iter"(%202) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      "cute.memref.store"(%202, %69, %150) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %67, %157) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %65, %164) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %63, %171) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %61, %178) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %59, %185) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %57, %192) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      "cute.memref.store"(%202, %55, %199) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %204 = "cute.derefine"(%203) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %205 = "builtin.unrealized_conversion_cast"(%204) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %206 = "llvm.load"(%205) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %207 = "llvm.icmp"(%206, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%207) ({
        %422 = "builtin.unrealized_conversion_cast"(%139) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %423 = "builtin.unrealized_conversion_cast"(%141) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %424 = "llvm.load"(%422) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%424, %423) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %208 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
      %209 = "cute.add_offset"(%203, %208) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %210 = "builtin.unrealized_conversion_cast"(%209) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %211 = "llvm.load"(%210) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %212 = "llvm.icmp"(%211, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%212) ({
        %417 = "cute.add_offset"(%139, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
        %418 = "cute.add_offset"(%141, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %419 = "builtin.unrealized_conversion_cast"(%417) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %420 = "builtin.unrealized_conversion_cast"(%418) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %421 = "llvm.load"(%419) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%421, %420) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %213 = "cute.add_offset"(%203, %48) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %214 = "cute.derefine"(%213) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %215 = "builtin.unrealized_conversion_cast"(%214) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %216 = "llvm.load"(%215) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %217 = "llvm.icmp"(%216, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%217) ({
        %412 = "cute.add_offset"(%139, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
        %413 = "cute.add_offset"(%141, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %414 = "builtin.unrealized_conversion_cast"(%412) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %415 = "builtin.unrealized_conversion_cast"(%413) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %416 = "llvm.load"(%414) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%416, %415) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %218 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
      %219 = "cute.add_offset"(%203, %218) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %220 = "builtin.unrealized_conversion_cast"(%219) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %221 = "llvm.load"(%220) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %222 = "llvm.icmp"(%221, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%222) ({
        %407 = "cute.add_offset"(%139, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
        %408 = "cute.add_offset"(%141, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %409 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %410 = "builtin.unrealized_conversion_cast"(%408) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %411 = "llvm.load"(%409) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%411, %410) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %223 = "cute.add_offset"(%203, %44) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %224 = "cute.derefine"(%223) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %225 = "builtin.unrealized_conversion_cast"(%224) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %226 = "llvm.load"(%225) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %227 = "llvm.icmp"(%226, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%227) ({
        %402 = "cute.add_offset"(%139, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
        %403 = "cute.add_offset"(%141, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %404 = "builtin.unrealized_conversion_cast"(%402) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %405 = "builtin.unrealized_conversion_cast"(%403) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %406 = "llvm.load"(%404) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%406, %405) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %228 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
      %229 = "cute.add_offset"(%203, %228) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %230 = "builtin.unrealized_conversion_cast"(%229) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %231 = "llvm.load"(%230) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %232 = "llvm.icmp"(%231, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%232) ({
        %397 = "cute.add_offset"(%139, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
        %398 = "cute.add_offset"(%141, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        %399 = "builtin.unrealized_conversion_cast"(%397) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %400 = "builtin.unrealized_conversion_cast"(%398) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %401 = "llvm.load"(%399) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%401, %400) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %233 = "cute.add_offset"(%203, %40) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %234 = "cute.derefine"(%233) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %235 = "builtin.unrealized_conversion_cast"(%234) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %236 = "llvm.load"(%235) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %237 = "llvm.icmp"(%236, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%237) ({
        %392 = "cute.add_offset"(%139, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
        %393 = "cute.add_offset"(%141, %31) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %394 = "builtin.unrealized_conversion_cast"(%392) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %395 = "builtin.unrealized_conversion_cast"(%393) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %396 = "llvm.load"(%394) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%396, %395) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %238 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
      %239 = "cute.add_offset"(%203, %238) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %240 = "builtin.unrealized_conversion_cast"(%239) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %241 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %242 = "llvm.icmp"(%241, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%242) ({
        %387 = "cute.add_offset"(%139, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
        %388 = "cute.add_offset"(%141, %30) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        %389 = "builtin.unrealized_conversion_cast"(%387) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %390 = "builtin.unrealized_conversion_cast"(%388) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %391 = "llvm.load"(%389) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%391, %390) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %243 = "cute.get_iter"(%135) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      "scf.for"(%53, %71, %52) ({
      ^bb0(%arg11: i32):
        %379 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %380 = "cute.crd2idx"(%379, %29) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %381 = "cute.add_offset"(%130, %380) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %382 = "cute.crd2idx"(%379, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %383 = "cute.add_offset"(%243, %382) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %384 = "builtin.unrealized_conversion_cast"(%381) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %385 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %386 = "llvm.load"(%384) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%386, %385) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %244 = "cute.memref.load_vec"(%135) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %245 = "arith.extf"(%244) : (vector<64xbf16>) -> vector<64xf32>
      %246 = "arith.mulf"(%245, %245) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %247 = "vector.reduction"(%246, %27) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %248 = "nvvm.shfl.sync"(%26, %247, %25, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %249 = "arith.addf"(%248, %247) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %250 = "nvvm.shfl.sync"(%26, %249, %71, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %251 = "arith.addf"(%249, %250) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %252 = "nvvm.shfl.sync"(%26, %251, %23, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %253 = "arith.addf"(%251, %252) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %254 = "nvvm.shfl.sync"(%26, %253, %75, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %255 = "arith.addf"(%253, %254) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %256 = "nvvm.shfl.sync"(%26, %255, %52, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %257 = "arith.addf"(%255, %256) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %258 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %259 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %260 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %261 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %262 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %263 = "arith.muli"(%259, %261) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %264 = "arith.addi"(%80, %263) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %265 = "arith.muli"(%260, %261) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %266 = "arith.muli"(%265, %262) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %267 = "arith.addi"(%264, %266) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %268 = "arith.floordivsi"(%267, %22) : (i32, i32) -> i32
      %269 = "arith.floordivsi"(%268, %75) : (i32, i32) -> i32
      %270 = "arith.remsi"(%268, %75) : (i32, i32) -> i32
      %271 = "arith.cmpi"(%258, %53) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "scf.if"(%271) ({
        %378 = "cute.make_coord"(%269, %270) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%91, %378, %257) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "llvm.inline_asm"(%53) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %272 = "arith.cmpi"(%258, %75) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %273 = "scf.if"(%272) ({
        %376 = "cute.make_coord"(%269, %258) : (i32, i32) -> !cute.coord<"(?,?)">
        %377 = "cute.memref.load"(%91, %376) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%377) : (f32) -> ()
      }, {
        "scf.yield"(%27) : (f32) -> ()
      }) : (i1) -> f32
      %274 = "nvvm.shfl.sync"(%26, %273, %25, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %275 = "arith.addf"(%273, %274) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %276 = "nvvm.shfl.sync"(%26, %275, %71, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %277 = "arith.addf"(%275, %276) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %278 = "nvvm.shfl.sync"(%26, %277, %23, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %279 = "arith.addf"(%277, %278) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %280 = "nvvm.shfl.sync"(%26, %279, %75, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %281 = "arith.addf"(%279, %280) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %282 = "nvvm.shfl.sync"(%26, %281, %52, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %283 = "arith.addf"(%281, %282) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %284 = "arith.divf"(%283, %21) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %285 = "arith.addf"(%284, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %286 = "math.rsqrt"(%285) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%53) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "scf.for"(%53, %71, %52) ({
      ^bb0(%arg10: i32):
        %368 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
        %369 = "cute.crd2idx"(%368, %29) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %370 = "cute.add_offset"(%130, %369) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %371 = "cute.crd2idx"(%368, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %372 = "cute.add_offset"(%243, %371) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %373 = "builtin.unrealized_conversion_cast"(%370) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %374 = "builtin.unrealized_conversion_cast"(%372) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %375 = "llvm.load"(%373) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%375, %374) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %287 = "cute.memref.load_vec"(%135) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %288 = "arith.extf"(%287) : (vector<64xbf16>) -> vector<64xf32>
      %289 = "vector.broadcast"(%286) : (f32) -> vector<64xf32>
      %290 = "arith.mulf"(%288, %289) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %291 = "cute.memref.load_vec"(%142) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %292 = "arith.extf"(%291) : (vector<64xbf16>) -> vector<64xf32>
      %293 = "arith.mulf"(%290, %292) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %294 = "arith.truncf"(%293) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%294, %136) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%201) ({
        %295 = "cute.derefine"(%144) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
        %296 = "builtin.unrealized_conversion_cast"(%295) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %297 = "llvm.load"(%296) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %298 = "llvm.icmp"(%297, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%298) ({
          %365 = "builtin.unrealized_conversion_cast"(%137) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %366 = "builtin.unrealized_conversion_cast"(%131) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %367 = "llvm.load"(%365) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%367, %366) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %299 = "cute.add_offset"(%144, %208) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %300 = "builtin.unrealized_conversion_cast"(%299) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %301 = "llvm.load"(%300) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %302 = "llvm.icmp"(%301, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%302) ({
          %360 = "cute.add_offset"(%137, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %361 = "cute.add_offset"(%131, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %362 = "builtin.unrealized_conversion_cast"(%360) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %363 = "builtin.unrealized_conversion_cast"(%361) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %364 = "llvm.load"(%362) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%364, %363) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %303 = "cute.add_offset"(%144, %48) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %304 = "cute.derefine"(%303) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
        %305 = "builtin.unrealized_conversion_cast"(%304) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %306 = "llvm.load"(%305) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %307 = "llvm.icmp"(%306, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%307) ({
          %355 = "cute.add_offset"(%137, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %356 = "cute.add_offset"(%131, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %357 = "builtin.unrealized_conversion_cast"(%355) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %358 = "builtin.unrealized_conversion_cast"(%356) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %359 = "llvm.load"(%357) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%359, %358) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %308 = "cute.add_offset"(%144, %218) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %309 = "builtin.unrealized_conversion_cast"(%308) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %310 = "llvm.load"(%309) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %311 = "llvm.icmp"(%310, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%311) ({
          %350 = "cute.add_offset"(%137, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %351 = "cute.add_offset"(%131, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %352 = "builtin.unrealized_conversion_cast"(%350) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %353 = "builtin.unrealized_conversion_cast"(%351) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %354 = "llvm.load"(%352) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%354, %353) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %312 = "cute.add_offset"(%144, %44) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %313 = "cute.derefine"(%312) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
        %314 = "builtin.unrealized_conversion_cast"(%313) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %315 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %316 = "llvm.icmp"(%315, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%316) ({
          %345 = "cute.add_offset"(%137, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %346 = "cute.add_offset"(%131, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %347 = "builtin.unrealized_conversion_cast"(%345) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %348 = "builtin.unrealized_conversion_cast"(%346) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %349 = "llvm.load"(%347) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%349, %348) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %317 = "cute.add_offset"(%144, %228) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %318 = "builtin.unrealized_conversion_cast"(%317) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %319 = "llvm.load"(%318) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %320 = "llvm.icmp"(%319, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%320) ({
          %340 = "cute.add_offset"(%137, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %341 = "cute.add_offset"(%131, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %342 = "builtin.unrealized_conversion_cast"(%340) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %343 = "builtin.unrealized_conversion_cast"(%341) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %344 = "llvm.load"(%342) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%344, %343) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %321 = "cute.add_offset"(%144, %40) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %322 = "cute.derefine"(%321) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
        %323 = "builtin.unrealized_conversion_cast"(%322) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %324 = "llvm.load"(%323) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %325 = "llvm.icmp"(%324, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%325) ({
          %335 = "cute.add_offset"(%137, %31) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %336 = "cute.add_offset"(%131, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %337 = "builtin.unrealized_conversion_cast"(%335) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %338 = "builtin.unrealized_conversion_cast"(%336) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %339 = "llvm.load"(%337) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%339, %338) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %326 = "cute.add_offset"(%144, %238) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %327 = "builtin.unrealized_conversion_cast"(%326) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %328 = "llvm.load"(%327) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %329 = "llvm.icmp"(%328, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%329) ({
          %330 = "cute.add_offset"(%137, %30) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %331 = "cute.add_offset"(%131, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %332 = "builtin.unrealized_conversion_cast"(%330) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %333 = "builtin.unrealized_conversion_cast"(%331) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %334 = "llvm.load"(%332) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%334, %333) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
    %14 = "arith.ceildivsi"(%13, %4) : (i32, i32) -> i32
    %15 = "cute.make_int_tuple"(%14) : (i32) -> !cute.int_tuple<"?">
    %16 = "cute.get_leaves"(%15) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %17 = "cute.get_scalars"(%16) : (!cute.int_tuple<"?">) -> i32
    %18 = "cuda.launch_cfg.create"(%3, %2, %2, %0, %17, %2, %2, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%18, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%18, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %19 = "cuda.launch_ex"(%18, %9, %11, %10, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %20 = "cuda.cast"(%19) : (!cuda.result) -> i32
    "cuda.return_if_error"(%20) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
