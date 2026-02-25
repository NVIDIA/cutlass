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
      "cf.cond_br"(%201)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %202 = "cute.make_view"(%144, %51) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_1
      %203 = "cute.derefine"(%202) : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
      %204 = "cute.get_iter"(%203) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
      %205 = "builtin.unrealized_conversion_cast"(%204) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %206 = "llvm.load"(%205) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %207 = "llvm.trunc"(%206) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %208 = "cute.recast_iter"(%129) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %209 = "cute.recast_iter"(%130) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%209, %208, %207) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %210 = "cute.add_offset"(%129, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %211 = "cute.add_offset"(%130, %50) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
      %212 = "cute.add_offset"(%204, %54) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %213 = "builtin.unrealized_conversion_cast"(%212) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %214 = "llvm.load"(%213) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %215 = "llvm.trunc"(%214) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %216 = "cute.recast_iter"(%210) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %217 = "cute.recast_iter"(%211) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%217, %216, %215) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %218 = "cute.add_offset"(%129, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %219 = "cute.add_offset"(%130, %49) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %220 = "cute.add_offset"(%204, %48) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %221 = "builtin.unrealized_conversion_cast"(%220) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %222 = "llvm.load"(%221) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %223 = "llvm.trunc"(%222) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %224 = "cute.recast_iter"(%218) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %225 = "cute.recast_iter"(%219) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%225, %224, %223) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %226 = "cute.add_offset"(%129, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %227 = "cute.add_offset"(%130, %47) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
      %228 = "cute.add_offset"(%204, %46) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %229 = "builtin.unrealized_conversion_cast"(%228) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %230 = "llvm.load"(%229) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %231 = "llvm.trunc"(%230) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %232 = "cute.recast_iter"(%226) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %233 = "cute.recast_iter"(%227) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%233, %232, %231) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %234 = "cute.add_offset"(%129, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %235 = "cute.add_offset"(%130, %45) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %236 = "cute.add_offset"(%204, %44) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %237 = "builtin.unrealized_conversion_cast"(%236) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %238 = "llvm.load"(%237) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %239 = "llvm.trunc"(%238) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %240 = "cute.recast_iter"(%234) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %241 = "cute.recast_iter"(%235) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%241, %240, %239) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %242 = "cute.add_offset"(%129, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %243 = "cute.add_offset"(%130, %43) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
      %244 = "cute.add_offset"(%204, %42) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %245 = "builtin.unrealized_conversion_cast"(%244) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %246 = "llvm.load"(%245) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %247 = "llvm.trunc"(%246) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %248 = "cute.recast_iter"(%242) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %249 = "cute.recast_iter"(%243) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%249, %248, %247) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %250 = "cute.add_offset"(%129, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %251 = "cute.add_offset"(%130, %41) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %252 = "cute.add_offset"(%204, %40) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %253 = "builtin.unrealized_conversion_cast"(%252) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %254 = "llvm.load"(%253) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %255 = "llvm.trunc"(%254) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %256 = "cute.recast_iter"(%250) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %257 = "cute.recast_iter"(%251) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%257, %256, %255) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %258 = "cute.add_offset"(%129, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %259 = "cute.add_offset"(%130, %39) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
      %260 = "cute.add_offset"(%204, %38) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %261 = "builtin.unrealized_conversion_cast"(%260) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %262 = "llvm.load"(%261) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %263 = "llvm.trunc"(%262) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %264 = "cute.recast_iter"(%258) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %265 = "cute.recast_iter"(%259) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%265, %264, %263) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "nvvm.cp.async.commit.group"() : () -> ()
      %266 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %267 = "cute.get_iter"(%266) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      "cute.memref.store"(%266, %69, %150) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %67, %157) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %65, %164) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %63, %171) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %61, %178) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %59, %185) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %57, %192) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      "cute.memref.store"(%266, %55, %199) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %268 = "cute.derefine"(%267) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %269 = "builtin.unrealized_conversion_cast"(%268) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %270 = "llvm.load"(%269) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %271 = "llvm.icmp"(%270, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%271)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb3:  // pred: ^bb2
      %272 = "builtin.unrealized_conversion_cast"(%139) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %273 = "builtin.unrealized_conversion_cast"(%141) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %274 = "llvm.load"(%272) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%274, %273) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb4] : () -> ()
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %275 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
      %276 = "cute.add_offset"(%267, %275) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %277 = "builtin.unrealized_conversion_cast"(%276) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %278 = "llvm.load"(%277) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %279 = "llvm.icmp"(%278, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%279)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb5:  // pred: ^bb4
      %280 = "cute.add_offset"(%139, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %281 = "cute.add_offset"(%141, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %282 = "builtin.unrealized_conversion_cast"(%280) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %283 = "builtin.unrealized_conversion_cast"(%281) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %284 = "llvm.load"(%282) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%284, %283) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb6] : () -> ()
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %285 = "cute.add_offset"(%267, %48) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %286 = "cute.derefine"(%285) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %287 = "builtin.unrealized_conversion_cast"(%286) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %288 = "llvm.load"(%287) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %289 = "llvm.icmp"(%288, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%289)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb7:  // pred: ^bb6
      %290 = "cute.add_offset"(%139, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %291 = "cute.add_offset"(%141, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %292 = "builtin.unrealized_conversion_cast"(%290) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %293 = "builtin.unrealized_conversion_cast"(%291) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %294 = "llvm.load"(%292) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%294, %293) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb8] : () -> ()
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %295 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
      %296 = "cute.add_offset"(%267, %295) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %297 = "builtin.unrealized_conversion_cast"(%296) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %298 = "llvm.load"(%297) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %299 = "llvm.icmp"(%298, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%299)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb9:  // pred: ^bb8
      %300 = "cute.add_offset"(%139, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %301 = "cute.add_offset"(%141, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %302 = "builtin.unrealized_conversion_cast"(%300) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %303 = "builtin.unrealized_conversion_cast"(%301) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %304 = "llvm.load"(%302) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%304, %303) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb10] : () -> ()
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %305 = "cute.add_offset"(%267, %44) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %306 = "cute.derefine"(%305) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %307 = "builtin.unrealized_conversion_cast"(%306) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %308 = "llvm.load"(%307) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %309 = "llvm.icmp"(%308, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%309)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb11:  // pred: ^bb10
      %310 = "cute.add_offset"(%139, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %311 = "cute.add_offset"(%141, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %312 = "builtin.unrealized_conversion_cast"(%310) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %313 = "builtin.unrealized_conversion_cast"(%311) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %314 = "llvm.load"(%312) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%314, %313) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb12] : () -> ()
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %315 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
      %316 = "cute.add_offset"(%267, %315) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %317 = "builtin.unrealized_conversion_cast"(%316) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %318 = "llvm.load"(%317) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %319 = "llvm.icmp"(%318, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%319)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb13:  // pred: ^bb12
      %320 = "cute.add_offset"(%139, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %321 = "cute.add_offset"(%141, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %322 = "builtin.unrealized_conversion_cast"(%320) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %323 = "builtin.unrealized_conversion_cast"(%321) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %324 = "llvm.load"(%322) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%324, %323) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb14] : () -> ()
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %325 = "cute.add_offset"(%267, %40) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %326 = "cute.derefine"(%325) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %327 = "builtin.unrealized_conversion_cast"(%326) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %328 = "llvm.load"(%327) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %329 = "llvm.icmp"(%328, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%329)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb15:  // pred: ^bb14
      %330 = "cute.add_offset"(%139, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %331 = "cute.add_offset"(%141, %31) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %332 = "builtin.unrealized_conversion_cast"(%330) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %333 = "builtin.unrealized_conversion_cast"(%331) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %334 = "llvm.load"(%332) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%334, %333) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb16] : () -> ()
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %335 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
      %336 = "cute.add_offset"(%267, %335) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %337 = "builtin.unrealized_conversion_cast"(%336) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %338 = "llvm.load"(%337) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %339 = "llvm.icmp"(%338, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%339)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb17:  // pred: ^bb16
      %340 = "cute.add_offset"(%139, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %341 = "cute.add_offset"(%141, %30) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %342 = "builtin.unrealized_conversion_cast"(%340) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %343 = "builtin.unrealized_conversion_cast"(%341) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %344 = "llvm.load"(%342) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
      "llvm.store"(%344, %343) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      "cf.br"()[^bb18] : () -> ()
    ^bb18:  // 2 preds: ^bb16, ^bb17
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %345 = "cute.get_iter"(%135) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      "cf.br"(%53)[^bb19] : (i32) -> ()
    ^bb19(%346: i32):  // 2 preds: ^bb18, ^bb20
      %347 = "arith.cmpi"(%346, %71) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%347)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %348 = "cute.make_coord"(%346) : (i32) -> !cute.coord<"(_,?)">
      %349 = "cute.crd2idx"(%348, %29) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %350 = "cute.add_offset"(%130, %349) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %351 = "cute.crd2idx"(%348, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %352 = "cute.add_offset"(%345, %351) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %353 = "builtin.unrealized_conversion_cast"(%350) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
      %354 = "builtin.unrealized_conversion_cast"(%352) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %355 = "llvm.load"(%353) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%355, %354) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %356 = "arith.addi"(%346, %52) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%356)[^bb19] : (i32) -> ()
    ^bb21:  // pred: ^bb19
      %357 = "cute.memref.load_vec"(%135) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %358 = "arith.extf"(%357) : (vector<64xbf16>) -> vector<64xf32>
      %359 = "arith.mulf"(%358, %358) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %360 = "vector.reduction"(%359, %27) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %361 = "nvvm.shfl.sync"(%26, %360, %25, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %362 = "arith.addf"(%361, %360) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %363 = "nvvm.shfl.sync"(%26, %362, %71, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %364 = "arith.addf"(%362, %363) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %365 = "nvvm.shfl.sync"(%26, %364, %23, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %366 = "arith.addf"(%364, %365) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %367 = "nvvm.shfl.sync"(%26, %366, %75, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %368 = "arith.addf"(%366, %367) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %369 = "nvvm.shfl.sync"(%26, %368, %52, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %370 = "arith.addf"(%368, %369) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %371 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %372 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %373 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %374 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %375 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %376 = "arith.muli"(%372, %374) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %377 = "arith.addi"(%80, %376) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %378 = "arith.muli"(%373, %374) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %379 = "arith.muli"(%378, %375) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %380 = "arith.addi"(%377, %379) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %381 = "arith.floordivsi"(%380, %22) : (i32, i32) -> i32
      %382 = "arith.floordivsi"(%381, %75) : (i32, i32) -> i32
      %383 = "arith.remsi"(%381, %75) : (i32, i32) -> i32
      %384 = "arith.cmpi"(%371, %53) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%384)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %385 = "cute.make_coord"(%382, %383) : (i32, i32) -> !cute.coord<"(?,?)">
      "cute.memref.store"(%91, %385, %370) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      "cf.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      "llvm.inline_asm"(%53) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %386 = "arith.cmpi"(%371, %75) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%386)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %387 = "cute.make_coord"(%382, %371) : (i32, i32) -> !cute.coord<"(?,?)">
      %388 = "cute.memref.load"(%91, %387) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
      "cf.br"(%388)[^bb26] : (f32) -> ()
    ^bb25:  // pred: ^bb23
      "cf.br"(%27)[^bb26] : (f32) -> ()
    ^bb26(%389: f32):  // 2 preds: ^bb24, ^bb25
      "cf.br"()[^bb27] : () -> ()
    ^bb27:  // pred: ^bb26
      %390 = "nvvm.shfl.sync"(%26, %389, %25, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %391 = "arith.addf"(%389, %390) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %392 = "nvvm.shfl.sync"(%26, %391, %71, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %393 = "arith.addf"(%391, %392) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %394 = "nvvm.shfl.sync"(%26, %393, %23, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %395 = "arith.addf"(%393, %394) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %396 = "nvvm.shfl.sync"(%26, %395, %75, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %397 = "arith.addf"(%395, %396) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %398 = "nvvm.shfl.sync"(%26, %397, %52, %24) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %399 = "arith.addf"(%397, %398) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %400 = "arith.divf"(%399, %21) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %401 = "arith.addf"(%400, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %402 = "math.rsqrt"(%401) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%53) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      "cf.br"(%53)[^bb28] : (i32) -> ()
    ^bb28(%403: i32):  // 2 preds: ^bb27, ^bb29
      %404 = "arith.cmpi"(%403, %71) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%404)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #loop_annotation} : (i1) -> ()
    ^bb29:  // pred: ^bb28
      %405 = "cute.make_coord"(%403) : (i32) -> !cute.coord<"(_,?)">
      %406 = "cute.crd2idx"(%405, %29) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %407 = "cute.add_offset"(%130, %406) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %408 = "cute.crd2idx"(%405, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %409 = "cute.add_offset"(%345, %408) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %410 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
      %411 = "builtin.unrealized_conversion_cast"(%409) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %412 = "llvm.load"(%410) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
      "llvm.store"(%412, %411) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
      %413 = "arith.addi"(%403, %52) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%413)[^bb28] : (i32) -> ()
    ^bb30:  // pred: ^bb28
      %414 = "cute.memref.load_vec"(%135) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %415 = "arith.extf"(%414) : (vector<64xbf16>) -> vector<64xf32>
      %416 = "vector.broadcast"(%402) : (f32) -> vector<64xf32>
      %417 = "arith.mulf"(%415, %416) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %418 = "cute.memref.load_vec"(%142) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %419 = "arith.extf"(%418) : (vector<64xbf16>) -> vector<64xf32>
      %420 = "arith.mulf"(%417, %419) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %421 = "arith.truncf"(%420) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%421, %136) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "cf.cond_br"(%201)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb31:  // pred: ^bb30
      %422 = "cute.derefine"(%144) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %423 = "builtin.unrealized_conversion_cast"(%422) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %424 = "llvm.load"(%423) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %425 = "llvm.icmp"(%424, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%425)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %426 = "builtin.unrealized_conversion_cast"(%137) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %427 = "builtin.unrealized_conversion_cast"(%131) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %428 = "llvm.load"(%426) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%428, %427) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %429 = "cute.add_offset"(%144, %275) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %430 = "builtin.unrealized_conversion_cast"(%429) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %431 = "llvm.load"(%430) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %432 = "llvm.icmp"(%431, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%432)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %433 = "cute.add_offset"(%137, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %434 = "cute.add_offset"(%131, %50) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %435 = "builtin.unrealized_conversion_cast"(%433) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %436 = "builtin.unrealized_conversion_cast"(%434) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %437 = "llvm.load"(%435) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%437, %436) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %438 = "cute.add_offset"(%144, %48) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %439 = "cute.derefine"(%438) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %440 = "builtin.unrealized_conversion_cast"(%439) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %441 = "llvm.load"(%440) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %442 = "llvm.icmp"(%441, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%442)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %443 = "cute.add_offset"(%137, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %444 = "cute.add_offset"(%131, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %445 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %446 = "builtin.unrealized_conversion_cast"(%444) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %447 = "llvm.load"(%445) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%447, %446) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %448 = "cute.add_offset"(%144, %295) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %449 = "builtin.unrealized_conversion_cast"(%448) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %450 = "llvm.load"(%449) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %451 = "llvm.icmp"(%450, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%451)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %452 = "cute.add_offset"(%137, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %453 = "cute.add_offset"(%131, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %454 = "builtin.unrealized_conversion_cast"(%452) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %455 = "builtin.unrealized_conversion_cast"(%453) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %456 = "llvm.load"(%454) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%456, %455) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %457 = "cute.add_offset"(%144, %44) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %458 = "cute.derefine"(%457) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %459 = "builtin.unrealized_conversion_cast"(%458) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %460 = "llvm.load"(%459) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %461 = "llvm.icmp"(%460, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%461)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %462 = "cute.add_offset"(%137, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %463 = "cute.add_offset"(%131, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %464 = "builtin.unrealized_conversion_cast"(%462) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %465 = "builtin.unrealized_conversion_cast"(%463) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %466 = "llvm.load"(%464) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%466, %465) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %467 = "cute.add_offset"(%144, %315) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %468 = "builtin.unrealized_conversion_cast"(%467) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %469 = "llvm.load"(%468) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %470 = "llvm.icmp"(%469, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%470)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %471 = "cute.add_offset"(%137, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %472 = "cute.add_offset"(%131, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %473 = "builtin.unrealized_conversion_cast"(%471) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %474 = "builtin.unrealized_conversion_cast"(%472) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %475 = "llvm.load"(%473) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%475, %474) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %476 = "cute.add_offset"(%144, %40) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %477 = "cute.derefine"(%476) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %478 = "builtin.unrealized_conversion_cast"(%477) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %479 = "llvm.load"(%478) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %480 = "llvm.icmp"(%479, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%480)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %481 = "cute.add_offset"(%137, %31) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %482 = "cute.add_offset"(%131, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %483 = "builtin.unrealized_conversion_cast"(%481) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
      %484 = "builtin.unrealized_conversion_cast"(%482) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %485 = "llvm.load"(%483) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%485, %484) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %486 = "cute.add_offset"(%144, %335) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %487 = "builtin.unrealized_conversion_cast"(%486) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %488 = "llvm.load"(%487) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %489 = "llvm.icmp"(%488, %37) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%489)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %490 = "cute.add_offset"(%137, %30) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %491 = "cute.add_offset"(%131, %39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %492 = "builtin.unrealized_conversion_cast"(%490) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
      %493 = "builtin.unrealized_conversion_cast"(%491) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
      %494 = "llvm.load"(%492) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
      "llvm.store"(%494, %493) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
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
