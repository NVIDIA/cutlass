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
      %23 = "arith.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
      %24 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %25 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %26 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %27 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %28 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %29 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %30 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(8))">
      %31 = "cute.static"() : () -> !cute.layout<"(8,(8)):(1,(512))">
      %32 = "cute.static"() : () -> !cute.int_tuple<"56">
      %33 = "cute.static"() : () -> !cute.int_tuple<"48">
      %34 = "cute.static"() : () -> !cute.int_tuple<"40">
      %35 = "cute.static"() : () -> !cute.int_tuple<"32">
      %36 = "cute.static"() : () -> !cute.int_tuple<"24">
      %37 = "cute.static"() : () -> !cute.int_tuple<"16">
      %38 = "cute.static"() : () -> !cute.int_tuple<"8">
      %39 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %40 = "cute.static"() : () -> !cute.int_tuple<"7">
      %41 = "cute.static"() : () -> !cute.int_tuple<"3584">
      %42 = "cute.static"() : () -> !cute.int_tuple<"6">
      %43 = "cute.static"() : () -> !cute.int_tuple<"3072">
      %44 = "cute.static"() : () -> !cute.int_tuple<"5">
      %45 = "cute.static"() : () -> !cute.int_tuple<"2560">
      %46 = "cute.static"() : () -> !cute.int_tuple<"4">
      %47 = "cute.static"() : () -> !cute.int_tuple<"2048">
      %48 = "cute.static"() : () -> !cute.int_tuple<"3">
      %49 = "cute.static"() : () -> !cute.int_tuple<"1536">
      %50 = "cute.static"() : () -> !cute.int_tuple<"2">
      %51 = "cute.static"() : () -> !cute.int_tuple<"1024">
      %52 = "cute.static"() : () -> !cute.int_tuple<"512">
      %53 = "cute.static"() : () -> !cute.layout<"(8):(1)">
      %54 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %55 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %56 = "cute.static"() : () -> !cute.int_tuple<"1">
      %57 = "cute.static"() : () -> !cute.coord<"(7,0,0)">
      %58 = "cute.static"() : () -> !cute.int_tuple<"(0,3584)">
      %59 = "cute.static"() : () -> !cute.coord<"(6,0,0)">
      %60 = "cute.static"() : () -> !cute.int_tuple<"(0,3072)">
      %61 = "cute.static"() : () -> !cute.coord<"(5,0,0)">
      %62 = "cute.static"() : () -> !cute.int_tuple<"(0,2560)">
      %63 = "cute.static"() : () -> !cute.coord<"(4,0,0)">
      %64 = "cute.static"() : () -> !cute.int_tuple<"(0,2048)">
      %65 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
      %66 = "cute.static"() : () -> !cute.int_tuple<"(0,1536)">
      %67 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
      %68 = "cute.static"() : () -> !cute.int_tuple<"(0,1024)">
      %69 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
      %70 = "cute.static"() : () -> !cute.int_tuple<"(0,512)">
      %71 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      %72 = "arith.constant"() <{value = 4096 : i32}> : () -> i32
      %73 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %74 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %75 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %76 = "cute.static"() : () -> !cute.stride<"((4096,1),(8192,0))">
      %77 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %78 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %79 = "cute.static"() : () -> !cute.layout<"(2,2):(1,2)">
      %80 = "cute.static"() : () -> !cute.int_tuple<"16384">
      %81 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %82 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %83 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %84 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %85 = "cute.get_shape"(%84) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %86:2 = "cute.get_leaves"(%85) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %87 = "cute.to_int_tuple"(%86#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %88 = "cute.get_scalars"(%87) : (!cute.int_tuple<"?">) -> i32
      %89 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %90 = "cute.add_offset"(%89, %80) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %91 = "cute.recast_iter"(%89) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %92 = "cute.recast_iter"(%90) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %93 = "cute.make_view"(%92, %79) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(2,2):(1,2)">) -> !memref_smem_f32_
      %94 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %95 = "cute.get_shape"(%94) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %96:2 = "cute.get_leaves"(%95) : (!cute.shape<"(?,4096)">) -> (!cute.shape<"?">, !cute.shape<"4096">)
      %97 = "cute.to_int_tuple"(%96#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %98 = "cute.make_shape"(%97) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %99 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %100 = "cute.make_layout"(%98, %78) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,4096):(1@0,1@1)">
      %101 = "cute.make_coord"(%83) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %102 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %103 = "cute.get_scalars"(%102) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %104 = "arith.ceildivsi"(%103, %77) : (i32, i32) -> i32
      %105 = "cute.make_shape"(%104) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %106 = "cute.make_layout"(%105, %76) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %107 = "cute.crd2idx"(%101, %106) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %108 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %109 = "cute.add_offset"(%108, %107) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %110 = "cute.make_coord"(%83) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %111 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,4096):(4096,1)">
      %112 = "cute.get_scalars"(%111) <{only_dynamic}> : (!cute.layout<"(?,4096):(4096,1)">) -> i32
      %113 = "arith.ceildivsi"(%112, %77) : (i32, i32) -> i32
      %114 = "cute.make_shape"(%113) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %115 = "cute.make_layout"(%114, %76) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((4096,1),(8192,0))">) -> !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %116 = "cute.crd2idx"(%110, %115) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %117 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %118 = "cute.add_offset"(%117, %116) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %119 = "cute.make_coord"(%83) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %120 = "cute.get_scalars"(%100) <{only_dynamic}> : (!cute.layout<"(?,4096):(1@0,1@1)">) -> i32
      %121 = "arith.ceildivsi"(%120, %77) : (i32, i32) -> i32
      %122 = "cute.make_shape"(%121) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %123 = "cute.make_layout"(%122, %75) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((2,4096),(?,1))">, !cute.stride<"((1@0,1@1),(2@0,0))">) -> !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %124 = "cute.crd2idx"(%119, %123) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %125 = "cute.add_offset"(%99, %124) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.arith_tuple_iter<"(?{div=2},0)">
      %126 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %127 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %128 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %129 = "cute.make_tiled_copy"(%126) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
      %130 = "cute.make_tiled_copy"(%127) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %131 = "cute.make_tiled_copy"(%128) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
      %132 = "arith.divsi"(%82, %74) : (i32, i32) -> i32
      %133 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %134 = "arith.muli"(%133, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %135 = "arith.muli"(%132, %72) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %136 = "arith.addi"(%134, %135) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %137 = "cute.assume"(%136) : (i32) -> !cute.i32<divby 8>
      %138 = "cute.make_int_tuple"(%137) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %139 = "cute.add_offset"(%109, %138) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %140 = "arith.divsi"(%82, %74) : (i32, i32) -> i32
      %141 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %142 = "arith.muli"(%141, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %143 = "arith.muli"(%140, %72) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %144 = "arith.addi"(%142, %143) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %145 = "cute.assume"(%144) : (i32) -> !cute.i32<divby 8>
      %146 = "cute.make_int_tuple"(%145) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %147 = "cute.add_offset"(%91, %146) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %148 = "arith.divsi"(%82, %74) : (i32, i32) -> i32
      %149 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %150 = "arith.muli"(%149, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %151 = "arith.muli"(%148, %72) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %152 = "arith.addi"(%150, %151) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %153 = "cute.assume"(%152) : (i32) -> !cute.i32<divby 8>
      %154 = "cute.make_int_tuple"(%153) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %155 = "cute.add_offset"(%118, %154) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %156 = "arith.divsi"(%82, %74) : (i32, i32) -> i32
      %157 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %158 = "arith.muli"(%157, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %159 = "cute.assume"(%158) : (i32) -> !cute.i32<divby 8>
      %160 = "cute.make_int_tuple"(%156, %159) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %161 = "cute.add_offset"(%125, %160) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %162 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %163 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %164 = "cute.get_iter"(%163) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %165 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %166 = "arith.muli"(%165, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %167 = "cute.assume"(%166) : (i32) -> !cute.i32<divby 8>
      %168 = "cute.make_int_tuple"(%167) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %169 = "cute.add_offset"(%81, %168) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %170 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %171 = "cute.get_iter"(%170) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %172 = "cute.get_iter"(%170) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      %173 = "cute.make_view"(%172) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_
      %174 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %175 = "cute.get_iter"(%174) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %176 = "cute.deref_arith_tuple_iter"(%161) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %177:2 = "cute.get_leaves"(%176) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %178 = "cute.make_coord"(%177#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %179 = "cute.get_scalars"(%178) : (!cute.coord<"?{div=8}">) -> i32
      %180 = "arith.cmpi"(%179, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %181 = "arith.extui"(%180) : (i1) -> i8
      "cute.memref.store"(%174, %71, %181) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %182 = "cute.add_offset"(%161, %70) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %183 = "cute.deref_arith_tuple_iter"(%182) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %184:2 = "cute.get_leaves"(%183) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %185 = "cute.make_coord"(%184#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %186 = "cute.get_scalars"(%185) : (!cute.coord<"?{div=8}">) -> i32
      %187 = "arith.cmpi"(%186, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %188 = "arith.extui"(%187) : (i1) -> i8
      "cute.memref.store"(%174, %69, %188) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %189 = "cute.add_offset"(%161, %68) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %190 = "cute.deref_arith_tuple_iter"(%189) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %191:2 = "cute.get_leaves"(%190) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %192 = "cute.make_coord"(%191#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %193 = "cute.get_scalars"(%192) : (!cute.coord<"?{div=8}">) -> i32
      %194 = "arith.cmpi"(%193, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %195 = "arith.extui"(%194) : (i1) -> i8
      "cute.memref.store"(%174, %67, %195) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %196 = "cute.add_offset"(%161, %66) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %197 = "cute.deref_arith_tuple_iter"(%196) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %198:2 = "cute.get_leaves"(%197) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %199 = "cute.make_coord"(%198#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %200 = "cute.get_scalars"(%199) : (!cute.coord<"?{div=8}">) -> i32
      %201 = "arith.cmpi"(%200, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %202 = "arith.extui"(%201) : (i1) -> i8
      "cute.memref.store"(%174, %65, %202) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %203 = "cute.add_offset"(%161, %64) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %204 = "cute.deref_arith_tuple_iter"(%203) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %205:2 = "cute.get_leaves"(%204) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %206 = "cute.make_coord"(%205#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %207 = "cute.get_scalars"(%206) : (!cute.coord<"?{div=8}">) -> i32
      %208 = "arith.cmpi"(%207, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %209 = "arith.extui"(%208) : (i1) -> i8
      "cute.memref.store"(%174, %63, %209) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %210 = "cute.add_offset"(%161, %62) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %211 = "cute.deref_arith_tuple_iter"(%210) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %212:2 = "cute.get_leaves"(%211) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %213 = "cute.make_coord"(%212#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %214 = "cute.get_scalars"(%213) : (!cute.coord<"?{div=8}">) -> i32
      %215 = "arith.cmpi"(%214, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %216 = "arith.extui"(%215) : (i1) -> i8
      "cute.memref.store"(%174, %61, %216) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %217 = "cute.add_offset"(%161, %60) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %218 = "cute.deref_arith_tuple_iter"(%217) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %219:2 = "cute.get_leaves"(%218) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %220 = "cute.make_coord"(%219#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %221 = "cute.get_scalars"(%220) : (!cute.coord<"?{div=8}">) -> i32
      %222 = "arith.cmpi"(%221, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %223 = "arith.extui"(%222) : (i1) -> i8
      "cute.memref.store"(%174, %59, %223) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %224 = "cute.add_offset"(%161, %58) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %225 = "cute.deref_arith_tuple_iter"(%224) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %226:2 = "cute.get_leaves"(%225) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %227 = "cute.make_coord"(%226#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %228 = "cute.get_scalars"(%227) : (!cute.coord<"?{div=8}">) -> i32
      %229 = "arith.cmpi"(%228, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %230 = "arith.extui"(%229) : (i1) -> i8
      "cute.memref.store"(%174, %57, %230) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %231 = "cute.deref_arith_tuple_iter"(%161) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %232:2 = "cute.get_leaves"(%231) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %233 = "cute.get_scalars"(%232#0) : (!cute.int_tuple<"?">) -> i32
      %234 = "arith.cmpi"(%233, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "scf.if"(%234) ({
        %525 = "cute.make_view"(%175, %53) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_i8_1
        %526 = "cute.derefine"(%525) : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %527 = "cute.get_iter"(%526) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem>
        %528 = "builtin.unrealized_conversion_cast"(%527) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %529 = "llvm.load"(%528) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %530 = "llvm.trunc"(%529) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %531 = "cute.recast_iter"(%139) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %532 = "cute.recast_iter"(%147) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%532, %531, %530) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %533 = "cute.add_offset"(%139, %52) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
        %534 = "cute.add_offset"(%147, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
        %535 = "cute.add_offset"(%527, %56) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %536 = "builtin.unrealized_conversion_cast"(%535) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %537 = "llvm.load"(%536) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %538 = "llvm.trunc"(%537) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %539 = "cute.recast_iter"(%533) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %540 = "cute.recast_iter"(%534) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%540, %539, %538) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %541 = "cute.add_offset"(%139, %51) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
        %542 = "cute.add_offset"(%147, %51) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %543 = "cute.add_offset"(%527, %50) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %544 = "builtin.unrealized_conversion_cast"(%543) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %545 = "llvm.load"(%544) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %546 = "llvm.trunc"(%545) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %547 = "cute.recast_iter"(%541) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %548 = "cute.recast_iter"(%542) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%548, %547, %546) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %549 = "cute.add_offset"(%139, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
        %550 = "cute.add_offset"(%147, %49) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
        %551 = "cute.add_offset"(%527, %48) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %552 = "builtin.unrealized_conversion_cast"(%551) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %553 = "llvm.load"(%552) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %554 = "llvm.trunc"(%553) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %555 = "cute.recast_iter"(%549) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %556 = "cute.recast_iter"(%550) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%556, %555, %554) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %557 = "cute.add_offset"(%139, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
        %558 = "cute.add_offset"(%147, %47) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %559 = "cute.add_offset"(%527, %46) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %560 = "builtin.unrealized_conversion_cast"(%559) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %561 = "llvm.load"(%560) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %562 = "llvm.trunc"(%561) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %563 = "cute.recast_iter"(%557) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %564 = "cute.recast_iter"(%558) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%564, %563, %562) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %565 = "cute.add_offset"(%139, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
        %566 = "cute.add_offset"(%147, %45) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
        %567 = "cute.add_offset"(%527, %44) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %568 = "builtin.unrealized_conversion_cast"(%567) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %569 = "llvm.load"(%568) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %570 = "llvm.trunc"(%569) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %571 = "cute.recast_iter"(%565) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %572 = "cute.recast_iter"(%566) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%572, %571, %570) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %573 = "cute.add_offset"(%139, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
        %574 = "cute.add_offset"(%147, %43) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %575 = "cute.add_offset"(%527, %42) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %576 = "builtin.unrealized_conversion_cast"(%575) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %577 = "llvm.load"(%576) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %578 = "llvm.trunc"(%577) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %579 = "cute.recast_iter"(%573) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %580 = "cute.recast_iter"(%574) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%580, %579, %578) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        %581 = "cute.add_offset"(%139, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
        %582 = "cute.add_offset"(%147, %41) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
        %583 = "cute.add_offset"(%527, %40) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %584 = "builtin.unrealized_conversion_cast"(%583) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %585 = "llvm.load"(%584) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %586 = "llvm.trunc"(%585) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %587 = "cute.recast_iter"(%581) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %588 = "cute.recast_iter"(%582) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%588, %587, %586) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %235 = "arith.divsi"(%82, %74) : (i32, i32) -> i32
      %236 = "arith.remsi"(%82, %74) : (i32, i32) -> i32
      %237 = "arith.muli"(%236, %73) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %238 = "cute.assume"(%237) : (i32) -> !cute.i32<divby 8>
      %239 = "cute.make_int_tuple"(%235, %238) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %240 = "cute.add_offset"(%125, %239) : (!cute.arith_tuple_iter<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %241 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %242 = "cute.get_iter"(%241) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %243 = "cute.deref_arith_tuple_iter"(%240) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %244:2 = "cute.get_leaves"(%243) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %245 = "cute.make_coord"(%244#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %246 = "cute.get_scalars"(%245) : (!cute.coord<"?{div=8}">) -> i32
      %247 = "arith.cmpi"(%246, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %248 = "arith.extui"(%247) : (i1) -> i8
      "cute.memref.store"(%241, %71, %248) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %249 = "cute.add_offset"(%240, %70) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %250 = "cute.deref_arith_tuple_iter"(%249) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %251:2 = "cute.get_leaves"(%250) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %252 = "cute.make_coord"(%251#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %253 = "cute.get_scalars"(%252) : (!cute.coord<"?{div=8}">) -> i32
      %254 = "arith.cmpi"(%253, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %255 = "arith.extui"(%254) : (i1) -> i8
      "cute.memref.store"(%241, %69, %255) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %256 = "cute.add_offset"(%240, %68) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %257 = "cute.deref_arith_tuple_iter"(%256) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %258:2 = "cute.get_leaves"(%257) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %259 = "cute.make_coord"(%258#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %260 = "cute.get_scalars"(%259) : (!cute.coord<"?{div=8}">) -> i32
      %261 = "arith.cmpi"(%260, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %262 = "arith.extui"(%261) : (i1) -> i8
      "cute.memref.store"(%241, %67, %262) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %263 = "cute.add_offset"(%240, %66) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %264 = "cute.deref_arith_tuple_iter"(%263) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %265:2 = "cute.get_leaves"(%264) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %266 = "cute.make_coord"(%265#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %267 = "cute.get_scalars"(%266) : (!cute.coord<"?{div=8}">) -> i32
      %268 = "arith.cmpi"(%267, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %269 = "arith.extui"(%268) : (i1) -> i8
      "cute.memref.store"(%241, %65, %269) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %270 = "cute.add_offset"(%240, %64) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %271 = "cute.deref_arith_tuple_iter"(%270) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %272:2 = "cute.get_leaves"(%271) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %273 = "cute.make_coord"(%272#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %274 = "cute.get_scalars"(%273) : (!cute.coord<"?{div=8}">) -> i32
      %275 = "arith.cmpi"(%274, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %276 = "arith.extui"(%275) : (i1) -> i8
      "cute.memref.store"(%241, %63, %276) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %277 = "cute.add_offset"(%240, %62) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %278 = "cute.deref_arith_tuple_iter"(%277) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %279:2 = "cute.get_leaves"(%278) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %280 = "cute.make_coord"(%279#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %281 = "cute.get_scalars"(%280) : (!cute.coord<"?{div=8}">) -> i32
      %282 = "arith.cmpi"(%281, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %283 = "arith.extui"(%282) : (i1) -> i8
      "cute.memref.store"(%241, %61, %283) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %284 = "cute.add_offset"(%240, %60) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %285 = "cute.deref_arith_tuple_iter"(%284) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %286:2 = "cute.get_leaves"(%285) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %287 = "cute.make_coord"(%286#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %288 = "cute.get_scalars"(%287) : (!cute.coord<"?{div=8}">) -> i32
      %289 = "arith.cmpi"(%288, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %290 = "arith.extui"(%289) : (i1) -> i8
      "cute.memref.store"(%241, %59, %290) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %291 = "cute.add_offset"(%240, %58) : (!cute.arith_tuple_iter<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.arith_tuple_iter<"(?,?{div=8})">
      %292 = "cute.deref_arith_tuple_iter"(%291) : (!cute.arith_tuple_iter<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %293:2 = "cute.get_leaves"(%292) : (!cute.int_tuple<"(?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %294 = "cute.make_coord"(%293#1) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %295 = "cute.get_scalars"(%294) : (!cute.coord<"?{div=8}">) -> i32
      %296 = "arith.cmpi"(%295, %72) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %297 = "arith.extui"(%296) : (i1) -> i8
      "cute.memref.store"(%241, %57, %297) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %298 = "cute.derefine"(%242) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
      %299 = "builtin.unrealized_conversion_cast"(%298) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %300 = "llvm.load"(%299) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %301 = "llvm.icmp"(%300, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%301) ({
        %522 = "builtin.unrealized_conversion_cast"(%169) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %523 = "builtin.unrealized_conversion_cast"(%171) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %524 = "llvm.load"(%522) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%524, %523) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %302 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
      %303 = "cute.add_offset"(%242, %302) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %304 = "builtin.unrealized_conversion_cast"(%303) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %305 = "llvm.load"(%304) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %306 = "llvm.icmp"(%305, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%306) ({
        %517 = "cute.add_offset"(%169, %52) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
        %518 = "cute.add_offset"(%171, %38) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %519 = "builtin.unrealized_conversion_cast"(%517) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %520 = "builtin.unrealized_conversion_cast"(%518) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %521 = "llvm.load"(%519) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%521, %520) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %307 = "cute.add_offset"(%242, %50) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %308 = "cute.derefine"(%307) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %309 = "builtin.unrealized_conversion_cast"(%308) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %310 = "llvm.load"(%309) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %311 = "llvm.icmp"(%310, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%311) ({
        %512 = "cute.add_offset"(%169, %51) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
        %513 = "cute.add_offset"(%171, %37) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %514 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %515 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %516 = "llvm.load"(%514) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%516, %515) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %312 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
      %313 = "cute.add_offset"(%242, %312) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %314 = "builtin.unrealized_conversion_cast"(%313) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %315 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %316 = "llvm.icmp"(%315, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%316) ({
        %507 = "cute.add_offset"(%169, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
        %508 = "cute.add_offset"(%171, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %509 = "builtin.unrealized_conversion_cast"(%507) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %510 = "builtin.unrealized_conversion_cast"(%508) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %511 = "llvm.load"(%509) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%511, %510) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %317 = "cute.add_offset"(%242, %46) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %318 = "cute.derefine"(%317) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
      %319 = "builtin.unrealized_conversion_cast"(%318) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %320 = "llvm.load"(%319) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %321 = "llvm.icmp"(%320, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%321) ({
        %502 = "cute.add_offset"(%169, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
        %503 = "cute.add_offset"(%171, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %504 = "builtin.unrealized_conversion_cast"(%502) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %505 = "builtin.unrealized_conversion_cast"(%503) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %506 = "llvm.load"(%504) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%506, %505) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %322 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
      %323 = "cute.add_offset"(%242, %322) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %324 = "builtin.unrealized_conversion_cast"(%323) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %325 = "llvm.load"(%324) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %326 = "llvm.icmp"(%325, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%326) ({
        %497 = "cute.add_offset"(%169, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
        %498 = "cute.add_offset"(%171, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        %499 = "builtin.unrealized_conversion_cast"(%497) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %500 = "builtin.unrealized_conversion_cast"(%498) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %501 = "llvm.load"(%499) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%501, %500) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %327 = "cute.add_offset"(%242, %42) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %328 = "cute.derefine"(%327) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
      %329 = "builtin.unrealized_conversion_cast"(%328) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %330 = "llvm.load"(%329) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %331 = "llvm.icmp"(%330, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%331) ({
        %492 = "cute.add_offset"(%169, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
        %493 = "cute.add_offset"(%171, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %494 = "builtin.unrealized_conversion_cast"(%492) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %495 = "builtin.unrealized_conversion_cast"(%493) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
        %496 = "llvm.load"(%494) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%496, %495) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %332 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
      %333 = "cute.add_offset"(%242, %332) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %334 = "builtin.unrealized_conversion_cast"(%333) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %335 = "llvm.load"(%334) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %336 = "llvm.icmp"(%335, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%336) ({
        %487 = "cute.add_offset"(%169, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
        %488 = "cute.add_offset"(%171, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        %489 = "builtin.unrealized_conversion_cast"(%487) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
        %490 = "builtin.unrealized_conversion_cast"(%488) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %491 = "llvm.load"(%489) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
        "llvm.store"(%491, %490) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %337 = "cute.get_iter"(%162) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      "scf.for"(%55, %73, %54) ({
      ^bb0(%arg11: i32):
        %479 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
        %480 = "cute.crd2idx"(%479, %31) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %481 = "cute.add_offset"(%147, %480) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %482 = "cute.crd2idx"(%479, %30) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %483 = "cute.add_offset"(%337, %482) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %484 = "builtin.unrealized_conversion_cast"(%481) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %485 = "builtin.unrealized_conversion_cast"(%483) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %486 = "llvm.load"(%484) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%486, %485) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %338 = "cute.memref.load_vec"(%162) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %339 = "arith.extf"(%338) : (vector<64xbf16>) -> vector<64xf32>
      %340 = "arith.mulf"(%339, %339) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %341 = "vector.reduction"(%340, %29) <{fastmath = #arith.fastmath<none>, kind = #vector.kind<add>}> : (vector<64xf32>, f32) -> f32
      %342 = "nvvm.shfl.sync"(%28, %341, %27, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %343 = "arith.addf"(%342, %341) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %344 = "nvvm.shfl.sync"(%28, %343, %73, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %345 = "arith.addf"(%343, %344) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %346 = "nvvm.shfl.sync"(%28, %345, %25, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %347 = "arith.addf"(%345, %346) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %348 = "nvvm.shfl.sync"(%28, %347, %77, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %349 = "arith.addf"(%347, %348) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %350 = "nvvm.shfl.sync"(%28, %349, %54, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %351 = "arith.addf"(%349, %350) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %352 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
      %353 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %354 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %355 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
      %356 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %357 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
      %358 = "arith.muli"(%354, %356) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %359 = "arith.addi"(%353, %358) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %360 = "arith.muli"(%355, %356) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %361 = "arith.muli"(%360, %357) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %362 = "arith.addi"(%359, %361) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %363 = "arith.floordivsi"(%362, %24) : (i32, i32) -> i32
      %364 = "arith.floordivsi"(%363, %77) : (i32, i32) -> i32
      %365 = "arith.remsi"(%363, %77) : (i32, i32) -> i32
      %366 = "arith.cmpi"(%352, %55) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "scf.if"(%366) ({
        %478 = "cute.make_coord"(%364, %365) : (i32, i32) -> !cute.coord<"(?,?)">
        "cute.memref.store"(%93, %478, %351) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "llvm.inline_asm"(%55) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %367 = "arith.cmpi"(%352, %77) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %368 = "scf.if"(%367) ({
        %476 = "cute.make_coord"(%364, %352) : (i32, i32) -> !cute.coord<"(?,?)">
        %477 = "cute.memref.load"(%93, %476) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        "scf.yield"(%477) : (f32) -> ()
      }, {
        "scf.yield"(%29) : (f32) -> ()
      }) : (i1) -> f32
      %369 = "nvvm.shfl.sync"(%28, %368, %27, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %370 = "arith.addf"(%368, %369) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %371 = "nvvm.shfl.sync"(%28, %370, %73, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %372 = "arith.addf"(%370, %371) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %373 = "nvvm.shfl.sync"(%28, %372, %25, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %374 = "arith.addf"(%372, %373) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %375 = "nvvm.shfl.sync"(%28, %374, %77, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %376 = "arith.addf"(%374, %375) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %377 = "nvvm.shfl.sync"(%28, %376, %54, %26) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
      %378 = "arith.addf"(%376, %377) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %379 = "arith.divf"(%378, %23) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %380 = "arith.addf"(%379, %arg9) <{fastmath = #arith.fastmath<none>}> : (f32, f32) -> f32
      %381 = "math.rsqrt"(%380) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
      "llvm.inline_asm"(%55) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
      %382 = "cute.get_iter"(%162) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<32>>
      "scf.for"(%55, %73, %54) ({
      ^bb0(%arg10: i32):
        %468 = "cute.make_coord"(%arg10) : (i32) -> !cute.coord<"(_,?)">
        %469 = "cute.crd2idx"(%468, %31) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %470 = "cute.add_offset"(%147, %469) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %471 = "cute.crd2idx"(%468, %30) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %472 = "cute.add_offset"(%382, %471) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %473 = "builtin.unrealized_conversion_cast"(%470) : (!cute.ptr<bf16, smem, align<16>>) -> !llvm.ptr<3>
        %474 = "builtin.unrealized_conversion_cast"(%472) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %475 = "llvm.load"(%473) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%475, %474) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %383 = "cute.memref.load_vec"(%162) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %384 = "arith.extf"(%383) : (vector<64xbf16>) -> vector<64xf32>
      %385 = "vector.broadcast"(%381) : (f32) -> vector<64xf32>
      %386 = "arith.mulf"(%384, %385) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %387 = "cute.memref.load_vec"(%173) : (!memref_rmem_bf16_) -> vector<64xbf16>
      %388 = "arith.extf"(%387) : (vector<64xbf16>) -> vector<64xf32>
      %389 = "arith.mulf"(%386, %388) <{fastmath = #arith.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
      %390 = "arith.truncf"(%389) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%390, %163) : (vector<64xbf16>, !memref_rmem_bf16_) -> ()
      "scf.if"(%234) ({
        %391 = "cute.derefine"(%175) : (!cute.ptr<i8, rmem, align<32>>) -> !cute.ptr<i8, rmem>
        %392 = "builtin.unrealized_conversion_cast"(%391) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %393 = "llvm.load"(%392) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %394 = "llvm.icmp"(%393, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%394) ({
          %465 = "builtin.unrealized_conversion_cast"(%164) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %466 = "builtin.unrealized_conversion_cast"(%155) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %467 = "llvm.load"(%465) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%467, %466) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %395 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
        %396 = "cute.add_offset"(%175, %395) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %397 = "builtin.unrealized_conversion_cast"(%396) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %398 = "llvm.load"(%397) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %399 = "llvm.icmp"(%398, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%399) ({
          %460 = "cute.add_offset"(%164, %38) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %461 = "cute.add_offset"(%155, %52) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %462 = "builtin.unrealized_conversion_cast"(%460) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %463 = "builtin.unrealized_conversion_cast"(%461) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %464 = "llvm.load"(%462) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%464, %463) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %400 = "cute.add_offset"(%175, %50) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %401 = "cute.derefine"(%400) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
        %402 = "builtin.unrealized_conversion_cast"(%401) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %403 = "llvm.load"(%402) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %404 = "llvm.icmp"(%403, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%404) ({
          %455 = "cute.add_offset"(%164, %37) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %456 = "cute.add_offset"(%155, %51) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %457 = "builtin.unrealized_conversion_cast"(%455) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %458 = "builtin.unrealized_conversion_cast"(%456) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %459 = "llvm.load"(%457) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%459, %458) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %405 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
        %406 = "cute.add_offset"(%175, %405) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %407 = "builtin.unrealized_conversion_cast"(%406) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %408 = "llvm.load"(%407) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %409 = "llvm.icmp"(%408, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%409) ({
          %450 = "cute.add_offset"(%164, %36) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %451 = "cute.add_offset"(%155, %49) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %452 = "builtin.unrealized_conversion_cast"(%450) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %453 = "builtin.unrealized_conversion_cast"(%451) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %454 = "llvm.load"(%452) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%454, %453) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %410 = "cute.add_offset"(%175, %46) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %411 = "cute.derefine"(%410) : (!cute.ptr<i8, rmem, align<4>>) -> !cute.ptr<i8, rmem>
        %412 = "builtin.unrealized_conversion_cast"(%411) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %413 = "llvm.load"(%412) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %414 = "llvm.icmp"(%413, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%414) ({
          %445 = "cute.add_offset"(%164, %35) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %446 = "cute.add_offset"(%155, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %447 = "builtin.unrealized_conversion_cast"(%445) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %448 = "builtin.unrealized_conversion_cast"(%446) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %449 = "llvm.load"(%447) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%449, %448) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %415 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
        %416 = "cute.add_offset"(%175, %415) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %417 = "builtin.unrealized_conversion_cast"(%416) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %418 = "llvm.load"(%417) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %419 = "llvm.icmp"(%418, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%419) ({
          %440 = "cute.add_offset"(%164, %34) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %441 = "cute.add_offset"(%155, %45) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %442 = "builtin.unrealized_conversion_cast"(%440) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %443 = "builtin.unrealized_conversion_cast"(%441) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %444 = "llvm.load"(%442) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%444, %443) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %420 = "cute.add_offset"(%175, %42) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %421 = "cute.derefine"(%420) : (!cute.ptr<i8, rmem, align<2>>) -> !cute.ptr<i8, rmem>
        %422 = "builtin.unrealized_conversion_cast"(%421) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %423 = "llvm.load"(%422) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %424 = "llvm.icmp"(%423, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%424) ({
          %435 = "cute.add_offset"(%164, %33) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %436 = "cute.add_offset"(%155, %43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %437 = "builtin.unrealized_conversion_cast"(%435) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
          %438 = "builtin.unrealized_conversion_cast"(%436) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %439 = "llvm.load"(%437) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%439, %438) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %425 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
        %426 = "cute.add_offset"(%175, %425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %427 = "builtin.unrealized_conversion_cast"(%426) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %428 = "llvm.load"(%427) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %429 = "llvm.icmp"(%428, %39) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%429) ({
          %430 = "cute.add_offset"(%164, %32) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %431 = "cute.add_offset"(%155, %41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %432 = "builtin.unrealized_conversion_cast"(%430) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          %433 = "builtin.unrealized_conversion_cast"(%431) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
          %434 = "llvm.load"(%432) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
          "llvm.store"(%434, %433) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
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
    %10 = "cute.make_shape"(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %11 = "cute.make_layout"(%10, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,4096)">, !cute.stride<"(4096,1)">) -> !cute.layout<"(?,4096):(4096,1)">
    %12 = "cute.make_view"(%arg2, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,4096):(4096,1)">) -> !memref_gmem_bf16_
    %13 = "cute.make_view"(%arg1, %5) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(4096):(1)">) -> !memref_gmem_bf16_1
    %14 = "cute.make_int_tuple"(%arg3) : (i32) -> !cute.int_tuple<"?">
    %15 = "cute.get_scalars"(%14) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
    %16 = "arith.ceildivsi"(%15, %4) : (i32, i32) -> i32
    %17 = "cute.make_int_tuple"(%16) : (i32) -> !cute.int_tuple<"?">
    %18 = "cute.get_leaves"(%17) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %19 = "cute.get_scalars"(%18) : (!cute.int_tuple<"?">) -> i32
    %20 = "cuda.launch_cfg.create"(%3, %2, %2, %0, %19, %2, %2, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%20, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%20, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %21 = "cuda.launch_ex"(%20, %9, %13, %12, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %22 = "cuda.cast"(%21) : (!cuda.result) -> i32
    "cuda.return_if_error"(%22) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
