!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "((1,(4,4))):((0,(1,?{i64})))">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %86 = "cute.static"() : () -> !cute.layout<"(4,32):(32,1)">
      %87 = "cute.static"() : () -> !cute.layout<"(4,4):(4,1)">
      %88 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %89 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %90 = "cute.make_coord"(%89) : (i32) -> !cute.coord<"((_,_),?)">
      %91 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %92:4 = "cute.get_scalars"(%91) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %93 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %94 = "cute.make_stride"(%92#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %95 = "cute.make_layout"(%93, %94) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %96 = "cute.crd2idx"(%90, %91) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %97 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %98 = "cute.add_offset"(%97, %96) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %99 = "cute.make_view"(%98, %95) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %100 = "cute.make_coord"(%89) : (i32) -> !cute.coord<"((_,_),?)">
      %101 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %102:4 = "cute.get_scalars"(%101) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %103 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %104 = "cute.make_stride"(%102#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %105 = "cute.make_layout"(%103, %104) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %106 = "cute.crd2idx"(%100, %101) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %107 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %108 = "cute.add_offset"(%107, %106) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %109 = "cute.make_view"(%108, %105) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %110 = "cute.make_coord"(%89) : (i32) -> !cute.coord<"((_,_),?)">
      %111 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %112:4 = "cute.get_scalars"(%111) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %113 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %114 = "cute.make_stride"(%112#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %115 = "cute.make_layout"(%113, %114) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %116 = "cute.crd2idx"(%110, %111) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %117 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %118 = "cute.add_offset"(%117, %116) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %119 = "cute.make_view"(%118, %115) : (!cute.ptr<f32, gmem>, !cute.layout<"(16,128):(?{i64},1)">) -> !memref_gmem_f32_1
      %120 = "cute.make_coord"(%89) : (i32) -> !cute.coord<"((_,_),?)">
      %121 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %122 = "cute.crd2idx"(%120, %121) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %123 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %124 = "cute.add_offset"(%123, %122) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %125 = "cute.make_view"(%124) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %126 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %127 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %128 = "cute.make_tiled_copy"(%126) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %129 = "cute.make_tiled_copy"(%126) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %130 = "cute.make_tiled_copy"(%127) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %131 = "cute.make_coord"(%88) : (i32) -> !cute.coord<"?">
      %132 = "cute.get_iter"(%99) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %133 = "cute.get_layout"(%99) : (!memref_gmem_f32_1) -> !cute.layout<"(16,128):(?{i64},1)">
      %134 = "cute.get_scalars"(%133) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %135 = "cute.get_scalars"(%131) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %136 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %137 = "arith.muli"(%134, %136) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %138 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %139 = "arith.divsi"(%135, %138) : (i32, i32) -> i32
      %140 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %141 = "arith.remsi"(%135, %140) : (i32, i32) -> i32
      %142 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %143 = "arith.muli"(%141, %142) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %144 = "arith.extsi"(%139) : (i32) -> i64
      %145 = "arith.muli"(%144, %137) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %146 = "arith.extsi"(%143) : (i32) -> i64
      %147 = "arith.addi"(%146, %145) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %148 = "cute.assume"(%147) : (i64) -> !cute.i64<divby 4>
      %149 = "cute.make_int_tuple"(%148) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %150 = "cute.add_offset"(%132, %149) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %151 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %152 = "cute.make_stride"(%134) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %153 = "cute.make_layout"(%151, %152) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %154 = "cute.make_view"(%150, %153) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %155 = "cute.get_iter"(%154) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %156 = "cute.make_coord"(%88) : (i32) -> !cute.coord<"?">
      %157 = "cute.get_iter"(%109) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %158 = "cute.get_layout"(%109) : (!memref_gmem_f32_1) -> !cute.layout<"(16,128):(?{i64},1)">
      %159 = "cute.get_scalars"(%158) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %160 = "cute.get_scalars"(%156) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %161 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %162 = "arith.muli"(%159, %161) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %163 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %164 = "arith.divsi"(%160, %163) : (i32, i32) -> i32
      %165 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %166 = "arith.remsi"(%160, %165) : (i32, i32) -> i32
      %167 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %168 = "arith.muli"(%166, %167) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %169 = "arith.extsi"(%164) : (i32) -> i64
      %170 = "arith.muli"(%169, %162) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %171 = "arith.extsi"(%168) : (i32) -> i64
      %172 = "arith.addi"(%171, %170) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %173 = "cute.assume"(%172) : (i64) -> !cute.i64<divby 4>
      %174 = "cute.make_int_tuple"(%173) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %175 = "cute.add_offset"(%157, %174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %176 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %177 = "cute.make_stride"(%159) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %178 = "cute.make_layout"(%176, %177) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %179 = "cute.make_view"(%175, %178) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %180 = "cute.get_iter"(%179) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %181 = "cute.make_coord"(%88) : (i32) -> !cute.coord<"?">
      %182 = "cute.get_iter"(%119) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %183 = "cute.get_layout"(%119) : (!memref_gmem_f32_1) -> !cute.layout<"(16,128):(?{i64},1)">
      %184 = "cute.get_scalars"(%183) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %185 = "cute.get_scalars"(%181) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %186 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %187 = "arith.muli"(%184, %186) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %188 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %189 = "arith.divsi"(%185, %188) : (i32, i32) -> i32
      %190 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %191 = "arith.remsi"(%185, %190) : (i32, i32) -> i32
      %192 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %193 = "arith.muli"(%191, %192) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %194 = "arith.extsi"(%189) : (i32) -> i64
      %195 = "arith.muli"(%194, %187) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %196 = "arith.extsi"(%193) : (i32) -> i64
      %197 = "arith.addi"(%196, %195) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %198 = "cute.assume"(%197) : (i64) -> !cute.i64<divby 4>
      %199 = "cute.make_int_tuple"(%198) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %200 = "cute.add_offset"(%182, %199) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %201 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %202 = "cute.make_stride"(%184) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %203 = "cute.make_layout"(%201, %202) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %204 = "cute.make_view"(%200, %203) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %205 = "cute.get_iter"(%204) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %206 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %207 = "cute.memref.alloca"(%206) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %208 = "cute.get_iter"(%207) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %209 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %210 = "cute.memref.alloca"(%209) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %211 = "cute.get_iter"(%210) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %212 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %213 = "cute.memref.alloca"(%212) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %214 = "cute.get_iter"(%213) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %215 = "cute.make_coord"(%88) : (i32) -> !cute.coord<"?">
      %216 = "cute.get_iter"(%125) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %217 = "cute.get_scalars"(%215) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %218 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %219 = "arith.divsi"(%217, %218) : (i32, i32) -> i32
      %220 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %221 = "arith.remsi"(%217, %220) : (i32, i32) -> i32
      %222 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %223 = "arith.muli"(%221, %222) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %224 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %225 = "arith.muli"(%219, %224) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %226 = "cute.assume"(%225) : (i32) -> !cute.i32<divby 4>
      %227 = "cute.assume"(%223) : (i32) -> !cute.i32<divby 4>
      %228 = "cute.make_int_tuple"(%226, %227) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %229 = "cute.add_offset"(%216, %228) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %230 = "cute.make_view"(%229) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %231 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %232 = "cute.memref.alloca"(%231) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %233 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %234 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %235 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %236 = "scf.for"(%233, %234, %235, %232) ({
      ^bb0(%arg12: i32, %arg13: !memref_rmem_i8_):
        %1120 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"?">
        %1121 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %1122 = "cute.crd2idx"(%1120, %1121) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %1123 = "cute.get_iter"(%230) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
        %1124 = "cute.add_offset"(%1123, %1122) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %1125 = "cute.make_view"(%1124) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
        %1126 = "cute.get_iter"(%1125) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %1127 = "cute.deref_arith_tuple_iter"(%1126) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %1128:2 = "cute.get_leaves"(%1127) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %1129 = "cute.make_coord"(%1128#0, %1128#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %1130 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %1131:2 = "cute.get_scalars"(%1129) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %1132:2 = "cute.get_scalars"(%1130) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %1133 = "arith.constant"() <{value = true}> : () -> i1
        %1134 = "arith.cmpi"(%1131#0, %1132#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %1135 = "arith.andi"(%1133, %1134) : (i1, i1) -> i1
        %1136 = "arith.cmpi"(%1131#1, %1132#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %1137 = "arith.andi"(%1135, %1136) : (i1, i1) -> i1
        %1138 = "arith.extui"(%1137) : (i1) -> i8
        %1139 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg13, %1139, %1138) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg13) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %237 = "cute.get_iter"(%236) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %238 = "cute.get_layout"(%154) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %239 = "cute.static"() : () -> !cute.layout<"1:0">
      %240 = "cute.append_to_rank"(%238, %239) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %241 = "cute.make_view"(%155, %240) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %242 = "cute.get_iter"(%241) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %243 = "cute.get_layout"(%241) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %244 = "cute.get_scalars"(%243) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %245 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %246 = "cute.make_stride"(%244) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %247 = "cute.make_layout"(%245, %246) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %248 = "cute.make_view"(%242, %247) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %249 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %250 = "cute.make_view"(%208, %249) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %251 = "cute.get_iter"(%250) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %252 = "cute.make_view"(%251) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %253 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %254 = "cute.make_view"(%237, %253) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %255 = "cute.get_iter"(%254) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %256 = "cute.make_view"(%255) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %257 = "cute.static"() : () -> !cute.layout<"1:0">
      %258 = "cute.get_iter"(%248) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %259 = "cute.get_iter"(%252) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %260 = "cute.get_layout"(%248) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %261 = "cute.append_to_rank"(%260, %257) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %262 = "cute.get_scalars"(%261) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %263 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %264 = "cute.make_stride"(%262) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %265 = "cute.make_layout"(%263, %264) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %266 = "cute.get_iter"(%256) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %267 = "cute.static"() : () -> !cute.int_tuple<"1">
      %268 = "cute.get_scalars"(%267) : (!cute.int_tuple<"1">) -> i32
      %269 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %270 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%269, %268, %270) ({
      ^bb0(%arg11: i32):
        %860 = "cute.get_scalars"(%265) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
        %861 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
        %862 = "cute.make_stride"(%860) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %863 = "cute.make_layout"(%861, %862) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %864 = "cute.static"() : () -> !cute.int_tuple<"0">
        %865 = "cute.add_offset"(%258, %864) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %866 = "cute.make_view"(%865, %863) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %867 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %868 = "cute.static"() : () -> !cute.int_tuple<"0">
        %869 = "cute.add_offset"(%259, %868) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %870 = "cute.make_view"(%869, %867) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %871 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %872 = "cute.static"() : () -> !cute.int_tuple<"0">
        %873 = "cute.add_offset"(%266, %872) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %874 = "cute.make_view"(%873, %871) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        %875 = "cute.get_iter"(%866) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %876 = "cute.get_layout"(%866) : (!memref_gmem_f32_4) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %877 = "cute.get_scalars"(%876) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
        %878 = "cute.get_iter"(%870) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %879 = "cute.get_iter"(%874) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %880 = "builtin.unrealized_conversion_cast"(%879) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %881 = "llvm.load"(%880) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %882 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %883 = "llvm.icmp"(%881, %882) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%883) ({
          %1117 = "builtin.unrealized_conversion_cast"(%875) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1118 = "builtin.unrealized_conversion_cast"(%878) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %1119 = "llvm.load"(%1117) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1119, %1118) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %884 = "cute.static"() : () -> !cute.int_tuple<"1">
        %885 = "cute.add_offset"(%879, %884) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %886 = "builtin.unrealized_conversion_cast"(%885) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %887 = "llvm.load"(%886) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %888 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %889 = "llvm.icmp"(%887, %888) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%889) ({
          %1110 = "cute.static"() : () -> !cute.int_tuple<"1">
          %1111 = "cute.add_offset"(%875, %1110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %1112 = "cute.static"() : () -> !cute.int_tuple<"1">
          %1113 = "cute.add_offset"(%878, %1112) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %1114 = "builtin.unrealized_conversion_cast"(%1111) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1115 = "builtin.unrealized_conversion_cast"(%1113) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1116 = "llvm.load"(%1114) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1116, %1115) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %890 = "cute.static"() : () -> !cute.int_tuple<"2">
        %891 = "cute.add_offset"(%879, %890) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %892 = "builtin.unrealized_conversion_cast"(%891) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %893 = "llvm.load"(%892) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %894 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %895 = "llvm.icmp"(%893, %894) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%895) ({
          %1103 = "cute.static"() : () -> !cute.int_tuple<"2">
          %1104 = "cute.add_offset"(%875, %1103) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %1105 = "cute.static"() : () -> !cute.int_tuple<"2">
          %1106 = "cute.add_offset"(%878, %1105) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %1107 = "builtin.unrealized_conversion_cast"(%1104) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1108 = "builtin.unrealized_conversion_cast"(%1106) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %1109 = "llvm.load"(%1107) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1109, %1108) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %896 = "cute.static"() : () -> !cute.int_tuple<"3">
        %897 = "cute.add_offset"(%879, %896) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %898 = "builtin.unrealized_conversion_cast"(%897) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %899 = "llvm.load"(%898) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %900 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %901 = "llvm.icmp"(%899, %900) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%901) ({
          %1096 = "cute.static"() : () -> !cute.int_tuple<"3">
          %1097 = "cute.add_offset"(%875, %1096) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %1098 = "cute.static"() : () -> !cute.int_tuple<"3">
          %1099 = "cute.add_offset"(%878, %1098) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %1100 = "builtin.unrealized_conversion_cast"(%1097) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1101 = "builtin.unrealized_conversion_cast"(%1099) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1102 = "llvm.load"(%1100) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1102, %1101) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %902 = "cute.static"() : () -> !cute.int_tuple<"4">
        %903 = "cute.add_offset"(%879, %902) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %904 = "builtin.unrealized_conversion_cast"(%903) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %905 = "llvm.load"(%904) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %906 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %907 = "llvm.icmp"(%905, %906) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%907) ({
          %1089 = "cute.make_int_tuple"(%877) : (i64) -> !cute.int_tuple<"?{i64}">
          %1090 = "cute.add_offset"(%875, %1089) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1091 = "cute.static"() : () -> !cute.int_tuple<"4">
          %1092 = "cute.add_offset"(%878, %1091) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %1093 = "builtin.unrealized_conversion_cast"(%1090) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1094 = "builtin.unrealized_conversion_cast"(%1092) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %1095 = "llvm.load"(%1093) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1095, %1094) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %908 = "cute.static"() : () -> !cute.int_tuple<"5">
        %909 = "cute.add_offset"(%879, %908) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %910 = "builtin.unrealized_conversion_cast"(%909) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %911 = "llvm.load"(%910) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %912 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %913 = "llvm.icmp"(%911, %912) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%913) ({
          %1080 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %1081 = "arith.addi"(%877, %1080) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1082 = "cute.make_int_tuple"(%1081) : (i64) -> !cute.int_tuple<"?{i64}">
          %1083 = "cute.add_offset"(%875, %1082) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1084 = "cute.static"() : () -> !cute.int_tuple<"5">
          %1085 = "cute.add_offset"(%878, %1084) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %1086 = "builtin.unrealized_conversion_cast"(%1083) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1087 = "builtin.unrealized_conversion_cast"(%1085) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1088 = "llvm.load"(%1086) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1088, %1087) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %914 = "cute.static"() : () -> !cute.int_tuple<"6">
        %915 = "cute.add_offset"(%879, %914) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %916 = "builtin.unrealized_conversion_cast"(%915) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %917 = "llvm.load"(%916) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %918 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %919 = "llvm.icmp"(%917, %918) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%919) ({
          %1071 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1072 = "arith.addi"(%877, %1071) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1073 = "cute.make_int_tuple"(%1072) : (i64) -> !cute.int_tuple<"?{i64}">
          %1074 = "cute.add_offset"(%875, %1073) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1075 = "cute.static"() : () -> !cute.int_tuple<"6">
          %1076 = "cute.add_offset"(%878, %1075) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %1077 = "builtin.unrealized_conversion_cast"(%1074) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1078 = "builtin.unrealized_conversion_cast"(%1076) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %1079 = "llvm.load"(%1077) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1079, %1078) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %920 = "cute.static"() : () -> !cute.int_tuple<"7">
        %921 = "cute.add_offset"(%879, %920) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %922 = "builtin.unrealized_conversion_cast"(%921) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %923 = "llvm.load"(%922) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %924 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %925 = "llvm.icmp"(%923, %924) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%925) ({
          %1062 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %1063 = "arith.addi"(%877, %1062) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1064 = "cute.make_int_tuple"(%1063) : (i64) -> !cute.int_tuple<"?{i64}">
          %1065 = "cute.add_offset"(%875, %1064) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1066 = "cute.static"() : () -> !cute.int_tuple<"7">
          %1067 = "cute.add_offset"(%878, %1066) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %1068 = "builtin.unrealized_conversion_cast"(%1065) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1069 = "builtin.unrealized_conversion_cast"(%1067) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1070 = "llvm.load"(%1068) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1070, %1069) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %926 = "cute.static"() : () -> !cute.int_tuple<"8">
        %927 = "cute.add_offset"(%879, %926) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %928 = "builtin.unrealized_conversion_cast"(%927) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
        %929 = "llvm.load"(%928) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %930 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %931 = "llvm.icmp"(%929, %930) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%931) ({
          %1052 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1053 = "arith.muli"(%877, %1052) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1054 = "cute.assume"(%1053) : (i64) -> !cute.i64<divby 2>
          %1055 = "cute.make_int_tuple"(%1054) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %1056 = "cute.add_offset"(%875, %1055) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %1057 = "cute.static"() : () -> !cute.int_tuple<"8">
          %1058 = "cute.add_offset"(%878, %1057) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %1059 = "builtin.unrealized_conversion_cast"(%1056) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1060 = "builtin.unrealized_conversion_cast"(%1058) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %1061 = "llvm.load"(%1059) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1061, %1060) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %932 = "cute.static"() : () -> !cute.int_tuple<"9">
        %933 = "cute.add_offset"(%879, %932) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %934 = "builtin.unrealized_conversion_cast"(%933) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %935 = "llvm.load"(%934) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %936 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %937 = "llvm.icmp"(%935, %936) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%937) ({
          %1041 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1042 = "arith.muli"(%877, %1041) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1043 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %1044 = "arith.addi"(%1042, %1043) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1045 = "cute.make_int_tuple"(%1044) : (i64) -> !cute.int_tuple<"?{i64}">
          %1046 = "cute.add_offset"(%875, %1045) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1047 = "cute.static"() : () -> !cute.int_tuple<"9">
          %1048 = "cute.add_offset"(%878, %1047) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %1049 = "builtin.unrealized_conversion_cast"(%1046) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1050 = "builtin.unrealized_conversion_cast"(%1048) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1051 = "llvm.load"(%1049) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1051, %1050) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %938 = "cute.static"() : () -> !cute.int_tuple<"10">
        %939 = "cute.add_offset"(%879, %938) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %940 = "builtin.unrealized_conversion_cast"(%939) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %941 = "llvm.load"(%940) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %942 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %943 = "llvm.icmp"(%941, %942) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%943) ({
          %1029 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1030 = "arith.muli"(%877, %1029) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1031 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1032 = "arith.addi"(%1030, %1031) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1033 = "cute.assume"(%1032) : (i64) -> !cute.i64<divby 2>
          %1034 = "cute.make_int_tuple"(%1033) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %1035 = "cute.add_offset"(%875, %1034) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %1036 = "cute.static"() : () -> !cute.int_tuple<"10">
          %1037 = "cute.add_offset"(%878, %1036) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %1038 = "builtin.unrealized_conversion_cast"(%1035) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1039 = "builtin.unrealized_conversion_cast"(%1037) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %1040 = "llvm.load"(%1038) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1040, %1039) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %944 = "cute.static"() : () -> !cute.int_tuple<"11">
        %945 = "cute.add_offset"(%879, %944) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %946 = "builtin.unrealized_conversion_cast"(%945) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %947 = "llvm.load"(%946) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %948 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %949 = "llvm.icmp"(%947, %948) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%949) ({
          %1018 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %1019 = "arith.muli"(%877, %1018) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1020 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %1021 = "arith.addi"(%1019, %1020) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1022 = "cute.make_int_tuple"(%1021) : (i64) -> !cute.int_tuple<"?{i64}">
          %1023 = "cute.add_offset"(%875, %1022) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1024 = "cute.static"() : () -> !cute.int_tuple<"11">
          %1025 = "cute.add_offset"(%878, %1024) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %1026 = "builtin.unrealized_conversion_cast"(%1023) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1027 = "builtin.unrealized_conversion_cast"(%1025) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1028 = "llvm.load"(%1026) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1028, %1027) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %950 = "cute.static"() : () -> !cute.int_tuple<"12">
        %951 = "cute.add_offset"(%879, %950) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %952 = "builtin.unrealized_conversion_cast"(%951) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %953 = "llvm.load"(%952) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %954 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %955 = "llvm.icmp"(%953, %954) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%955) ({
          %1008 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %1009 = "arith.muli"(%877, %1008) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1010 = "cute.assume"(%1009) : (i64) -> !cute.i64<divby 3>
          %1011 = "cute.make_int_tuple"(%1010) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %1012 = "cute.add_offset"(%875, %1011) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %1013 = "cute.static"() : () -> !cute.int_tuple<"12">
          %1014 = "cute.add_offset"(%878, %1013) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %1015 = "builtin.unrealized_conversion_cast"(%1012) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1016 = "builtin.unrealized_conversion_cast"(%1014) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %1017 = "llvm.load"(%1015) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1017, %1016) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %956 = "cute.static"() : () -> !cute.int_tuple<"13">
        %957 = "cute.add_offset"(%879, %956) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %958 = "builtin.unrealized_conversion_cast"(%957) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %959 = "llvm.load"(%958) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %960 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %961 = "llvm.icmp"(%959, %960) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%961) ({
          %997 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %998 = "arith.muli"(%877, %997) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %999 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %1000 = "arith.addi"(%998, %999) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %1001 = "cute.make_int_tuple"(%1000) : (i64) -> !cute.int_tuple<"?{i64}">
          %1002 = "cute.add_offset"(%875, %1001) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %1003 = "cute.static"() : () -> !cute.int_tuple<"13">
          %1004 = "cute.add_offset"(%878, %1003) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %1005 = "builtin.unrealized_conversion_cast"(%1002) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %1006 = "builtin.unrealized_conversion_cast"(%1004) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1007 = "llvm.load"(%1005) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%1007, %1006) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %962 = "cute.static"() : () -> !cute.int_tuple<"14">
        %963 = "cute.add_offset"(%879, %962) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %964 = "builtin.unrealized_conversion_cast"(%963) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %965 = "llvm.load"(%964) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %966 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %967 = "llvm.icmp"(%965, %966) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%967) ({
          %986 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %987 = "arith.muli"(%877, %986) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %988 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %989 = "arith.addi"(%987, %988) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %990 = "cute.make_int_tuple"(%989) : (i64) -> !cute.int_tuple<"?{i64}">
          %991 = "cute.add_offset"(%875, %990) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %992 = "cute.static"() : () -> !cute.int_tuple<"14">
          %993 = "cute.add_offset"(%878, %992) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %994 = "builtin.unrealized_conversion_cast"(%991) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %995 = "builtin.unrealized_conversion_cast"(%993) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %996 = "llvm.load"(%994) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%996, %995) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %968 = "cute.static"() : () -> !cute.int_tuple<"15">
        %969 = "cute.add_offset"(%879, %968) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %970 = "builtin.unrealized_conversion_cast"(%969) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %971 = "llvm.load"(%970) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %972 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %973 = "llvm.icmp"(%971, %972) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%973) ({
          %974 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %975 = "arith.muli"(%877, %974) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %976 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %977 = "arith.addi"(%975, %976) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %978 = "cute.assume"(%977) : (i64) -> !cute.i64<divby 3>
          %979 = "cute.make_int_tuple"(%978) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %980 = "cute.add_offset"(%875, %979) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %981 = "cute.static"() : () -> !cute.int_tuple<"15">
          %982 = "cute.add_offset"(%878, %981) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %983 = "builtin.unrealized_conversion_cast"(%980) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %984 = "builtin.unrealized_conversion_cast"(%982) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %985 = "llvm.load"(%983) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%985, %984) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %271 = "cute.get_layout"(%179) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %272 = "cute.static"() : () -> !cute.layout<"1:0">
      %273 = "cute.append_to_rank"(%271, %272) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %274 = "cute.make_view"(%180, %273) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %275 = "cute.get_iter"(%274) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %276 = "cute.get_layout"(%274) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %277 = "cute.get_scalars"(%276) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %278 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %279 = "cute.make_stride"(%277) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %280 = "cute.make_layout"(%278, %279) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %281 = "cute.make_view"(%275, %280) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %282 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %283 = "cute.make_view"(%211, %282) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %284 = "cute.get_iter"(%283) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %285 = "cute.make_view"(%284) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %286 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %287 = "cute.make_view"(%237, %286) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %288 = "cute.get_iter"(%287) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %289 = "cute.make_view"(%288) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %290 = "cute.static"() : () -> !cute.layout<"1:0">
      %291 = "cute.get_iter"(%281) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %292 = "cute.get_iter"(%285) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %293 = "cute.get_layout"(%281) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %294 = "cute.append_to_rank"(%293, %290) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %295 = "cute.get_scalars"(%294) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %296 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %297 = "cute.make_stride"(%295) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %298 = "cute.make_layout"(%296, %297) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %299 = "cute.get_iter"(%289) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %300 = "cute.static"() : () -> !cute.int_tuple<"1">
      %301 = "cute.get_scalars"(%300) : (!cute.int_tuple<"1">) -> i32
      %302 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %303 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%302, %301, %303) ({
      ^bb0(%arg10: i32):
        %600 = "cute.get_scalars"(%298) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
        %601 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
        %602 = "cute.make_stride"(%600) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %603 = "cute.make_layout"(%601, %602) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %604 = "cute.static"() : () -> !cute.int_tuple<"0">
        %605 = "cute.add_offset"(%291, %604) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %606 = "cute.make_view"(%605, %603) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %607 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %608 = "cute.static"() : () -> !cute.int_tuple<"0">
        %609 = "cute.add_offset"(%292, %608) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %610 = "cute.make_view"(%609, %607) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %611 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %612 = "cute.static"() : () -> !cute.int_tuple<"0">
        %613 = "cute.add_offset"(%299, %612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %614 = "cute.make_view"(%613, %611) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        %615 = "cute.get_iter"(%606) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %616 = "cute.get_layout"(%606) : (!memref_gmem_f32_4) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %617 = "cute.get_scalars"(%616) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
        %618 = "cute.get_iter"(%610) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %619 = "cute.get_iter"(%614) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %620 = "builtin.unrealized_conversion_cast"(%619) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %621 = "llvm.load"(%620) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %622 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %623 = "llvm.icmp"(%621, %622) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%623) ({
          %857 = "builtin.unrealized_conversion_cast"(%615) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %858 = "builtin.unrealized_conversion_cast"(%618) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %859 = "llvm.load"(%857) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%859, %858) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %624 = "cute.static"() : () -> !cute.int_tuple<"1">
        %625 = "cute.add_offset"(%619, %624) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %626 = "builtin.unrealized_conversion_cast"(%625) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %627 = "llvm.load"(%626) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %628 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %629 = "llvm.icmp"(%627, %628) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%629) ({
          %850 = "cute.static"() : () -> !cute.int_tuple<"1">
          %851 = "cute.add_offset"(%615, %850) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %852 = "cute.static"() : () -> !cute.int_tuple<"1">
          %853 = "cute.add_offset"(%618, %852) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %854 = "builtin.unrealized_conversion_cast"(%851) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %855 = "builtin.unrealized_conversion_cast"(%853) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %856 = "llvm.load"(%854) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%856, %855) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %630 = "cute.static"() : () -> !cute.int_tuple<"2">
        %631 = "cute.add_offset"(%619, %630) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %632 = "builtin.unrealized_conversion_cast"(%631) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %633 = "llvm.load"(%632) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %634 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %635 = "llvm.icmp"(%633, %634) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%635) ({
          %843 = "cute.static"() : () -> !cute.int_tuple<"2">
          %844 = "cute.add_offset"(%615, %843) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %845 = "cute.static"() : () -> !cute.int_tuple<"2">
          %846 = "cute.add_offset"(%618, %845) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %847 = "builtin.unrealized_conversion_cast"(%844) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %848 = "builtin.unrealized_conversion_cast"(%846) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %849 = "llvm.load"(%847) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%849, %848) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %636 = "cute.static"() : () -> !cute.int_tuple<"3">
        %637 = "cute.add_offset"(%619, %636) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %638 = "builtin.unrealized_conversion_cast"(%637) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %639 = "llvm.load"(%638) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %640 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %641 = "llvm.icmp"(%639, %640) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%641) ({
          %836 = "cute.static"() : () -> !cute.int_tuple<"3">
          %837 = "cute.add_offset"(%615, %836) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %838 = "cute.static"() : () -> !cute.int_tuple<"3">
          %839 = "cute.add_offset"(%618, %838) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %840 = "builtin.unrealized_conversion_cast"(%837) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %841 = "builtin.unrealized_conversion_cast"(%839) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %842 = "llvm.load"(%840) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%842, %841) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %642 = "cute.static"() : () -> !cute.int_tuple<"4">
        %643 = "cute.add_offset"(%619, %642) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %644 = "builtin.unrealized_conversion_cast"(%643) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %645 = "llvm.load"(%644) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %646 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %647 = "llvm.icmp"(%645, %646) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%647) ({
          %829 = "cute.make_int_tuple"(%617) : (i64) -> !cute.int_tuple<"?{i64}">
          %830 = "cute.add_offset"(%615, %829) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %831 = "cute.static"() : () -> !cute.int_tuple<"4">
          %832 = "cute.add_offset"(%618, %831) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %833 = "builtin.unrealized_conversion_cast"(%830) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %834 = "builtin.unrealized_conversion_cast"(%832) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %835 = "llvm.load"(%833) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%835, %834) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %648 = "cute.static"() : () -> !cute.int_tuple<"5">
        %649 = "cute.add_offset"(%619, %648) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %650 = "builtin.unrealized_conversion_cast"(%649) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %651 = "llvm.load"(%650) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %652 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %653 = "llvm.icmp"(%651, %652) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%653) ({
          %820 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %821 = "arith.addi"(%617, %820) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %822 = "cute.make_int_tuple"(%821) : (i64) -> !cute.int_tuple<"?{i64}">
          %823 = "cute.add_offset"(%615, %822) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %824 = "cute.static"() : () -> !cute.int_tuple<"5">
          %825 = "cute.add_offset"(%618, %824) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %826 = "builtin.unrealized_conversion_cast"(%823) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %827 = "builtin.unrealized_conversion_cast"(%825) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %828 = "llvm.load"(%826) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%828, %827) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %654 = "cute.static"() : () -> !cute.int_tuple<"6">
        %655 = "cute.add_offset"(%619, %654) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %656 = "builtin.unrealized_conversion_cast"(%655) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %657 = "llvm.load"(%656) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %658 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %659 = "llvm.icmp"(%657, %658) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%659) ({
          %811 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %812 = "arith.addi"(%617, %811) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %813 = "cute.make_int_tuple"(%812) : (i64) -> !cute.int_tuple<"?{i64}">
          %814 = "cute.add_offset"(%615, %813) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %815 = "cute.static"() : () -> !cute.int_tuple<"6">
          %816 = "cute.add_offset"(%618, %815) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %817 = "builtin.unrealized_conversion_cast"(%814) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %818 = "builtin.unrealized_conversion_cast"(%816) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %819 = "llvm.load"(%817) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%819, %818) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %660 = "cute.static"() : () -> !cute.int_tuple<"7">
        %661 = "cute.add_offset"(%619, %660) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %662 = "builtin.unrealized_conversion_cast"(%661) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %663 = "llvm.load"(%662) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %664 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %665 = "llvm.icmp"(%663, %664) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%665) ({
          %802 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %803 = "arith.addi"(%617, %802) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %804 = "cute.make_int_tuple"(%803) : (i64) -> !cute.int_tuple<"?{i64}">
          %805 = "cute.add_offset"(%615, %804) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %806 = "cute.static"() : () -> !cute.int_tuple<"7">
          %807 = "cute.add_offset"(%618, %806) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %808 = "builtin.unrealized_conversion_cast"(%805) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %809 = "builtin.unrealized_conversion_cast"(%807) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %810 = "llvm.load"(%808) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%810, %809) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %666 = "cute.static"() : () -> !cute.int_tuple<"8">
        %667 = "cute.add_offset"(%619, %666) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %668 = "builtin.unrealized_conversion_cast"(%667) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
        %669 = "llvm.load"(%668) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %670 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %671 = "llvm.icmp"(%669, %670) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%671) ({
          %792 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %793 = "arith.muli"(%617, %792) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %794 = "cute.assume"(%793) : (i64) -> !cute.i64<divby 2>
          %795 = "cute.make_int_tuple"(%794) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %796 = "cute.add_offset"(%615, %795) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %797 = "cute.static"() : () -> !cute.int_tuple<"8">
          %798 = "cute.add_offset"(%618, %797) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %799 = "builtin.unrealized_conversion_cast"(%796) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %800 = "builtin.unrealized_conversion_cast"(%798) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %801 = "llvm.load"(%799) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%801, %800) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %672 = "cute.static"() : () -> !cute.int_tuple<"9">
        %673 = "cute.add_offset"(%619, %672) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %674 = "builtin.unrealized_conversion_cast"(%673) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %675 = "llvm.load"(%674) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %676 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %677 = "llvm.icmp"(%675, %676) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%677) ({
          %781 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %782 = "arith.muli"(%617, %781) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %783 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %784 = "arith.addi"(%782, %783) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %785 = "cute.make_int_tuple"(%784) : (i64) -> !cute.int_tuple<"?{i64}">
          %786 = "cute.add_offset"(%615, %785) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %787 = "cute.static"() : () -> !cute.int_tuple<"9">
          %788 = "cute.add_offset"(%618, %787) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %789 = "builtin.unrealized_conversion_cast"(%786) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %790 = "builtin.unrealized_conversion_cast"(%788) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %791 = "llvm.load"(%789) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%791, %790) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %678 = "cute.static"() : () -> !cute.int_tuple<"10">
        %679 = "cute.add_offset"(%619, %678) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %680 = "builtin.unrealized_conversion_cast"(%679) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %681 = "llvm.load"(%680) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %682 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %683 = "llvm.icmp"(%681, %682) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%683) ({
          %769 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %770 = "arith.muli"(%617, %769) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %771 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %772 = "arith.addi"(%770, %771) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %773 = "cute.assume"(%772) : (i64) -> !cute.i64<divby 2>
          %774 = "cute.make_int_tuple"(%773) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %775 = "cute.add_offset"(%615, %774) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %776 = "cute.static"() : () -> !cute.int_tuple<"10">
          %777 = "cute.add_offset"(%618, %776) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %778 = "builtin.unrealized_conversion_cast"(%775) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %779 = "builtin.unrealized_conversion_cast"(%777) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %780 = "llvm.load"(%778) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%780, %779) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %684 = "cute.static"() : () -> !cute.int_tuple<"11">
        %685 = "cute.add_offset"(%619, %684) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %686 = "builtin.unrealized_conversion_cast"(%685) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %687 = "llvm.load"(%686) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %688 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %689 = "llvm.icmp"(%687, %688) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%689) ({
          %758 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %759 = "arith.muli"(%617, %758) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %760 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %761 = "arith.addi"(%759, %760) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %762 = "cute.make_int_tuple"(%761) : (i64) -> !cute.int_tuple<"?{i64}">
          %763 = "cute.add_offset"(%615, %762) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %764 = "cute.static"() : () -> !cute.int_tuple<"11">
          %765 = "cute.add_offset"(%618, %764) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %766 = "builtin.unrealized_conversion_cast"(%763) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %767 = "builtin.unrealized_conversion_cast"(%765) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %768 = "llvm.load"(%766) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%768, %767) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %690 = "cute.static"() : () -> !cute.int_tuple<"12">
        %691 = "cute.add_offset"(%619, %690) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %692 = "builtin.unrealized_conversion_cast"(%691) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %693 = "llvm.load"(%692) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %694 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %695 = "llvm.icmp"(%693, %694) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%695) ({
          %748 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %749 = "arith.muli"(%617, %748) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %750 = "cute.assume"(%749) : (i64) -> !cute.i64<divby 3>
          %751 = "cute.make_int_tuple"(%750) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %752 = "cute.add_offset"(%615, %751) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %753 = "cute.static"() : () -> !cute.int_tuple<"12">
          %754 = "cute.add_offset"(%618, %753) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %755 = "builtin.unrealized_conversion_cast"(%752) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %756 = "builtin.unrealized_conversion_cast"(%754) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %757 = "llvm.load"(%755) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%757, %756) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %696 = "cute.static"() : () -> !cute.int_tuple<"13">
        %697 = "cute.add_offset"(%619, %696) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %698 = "builtin.unrealized_conversion_cast"(%697) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %699 = "llvm.load"(%698) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %700 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %701 = "llvm.icmp"(%699, %700) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%701) ({
          %737 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %738 = "arith.muli"(%617, %737) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %739 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %740 = "arith.addi"(%738, %739) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %741 = "cute.make_int_tuple"(%740) : (i64) -> !cute.int_tuple<"?{i64}">
          %742 = "cute.add_offset"(%615, %741) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %743 = "cute.static"() : () -> !cute.int_tuple<"13">
          %744 = "cute.add_offset"(%618, %743) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %745 = "builtin.unrealized_conversion_cast"(%742) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %746 = "builtin.unrealized_conversion_cast"(%744) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %747 = "llvm.load"(%745) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%747, %746) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %702 = "cute.static"() : () -> !cute.int_tuple<"14">
        %703 = "cute.add_offset"(%619, %702) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %704 = "builtin.unrealized_conversion_cast"(%703) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %705 = "llvm.load"(%704) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %706 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %707 = "llvm.icmp"(%705, %706) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%707) ({
          %726 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %727 = "arith.muli"(%617, %726) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %728 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %729 = "arith.addi"(%727, %728) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %730 = "cute.make_int_tuple"(%729) : (i64) -> !cute.int_tuple<"?{i64}">
          %731 = "cute.add_offset"(%615, %730) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %732 = "cute.static"() : () -> !cute.int_tuple<"14">
          %733 = "cute.add_offset"(%618, %732) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %734 = "builtin.unrealized_conversion_cast"(%731) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %735 = "builtin.unrealized_conversion_cast"(%733) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %736 = "llvm.load"(%734) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%736, %735) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %708 = "cute.static"() : () -> !cute.int_tuple<"15">
        %709 = "cute.add_offset"(%619, %708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %710 = "builtin.unrealized_conversion_cast"(%709) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %711 = "llvm.load"(%710) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %712 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %713 = "llvm.icmp"(%711, %712) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%713) ({
          %714 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %715 = "arith.muli"(%617, %714) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %716 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %717 = "arith.addi"(%715, %716) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %718 = "cute.assume"(%717) : (i64) -> !cute.i64<divby 3>
          %719 = "cute.make_int_tuple"(%718) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %720 = "cute.add_offset"(%615, %719) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %721 = "cute.static"() : () -> !cute.int_tuple<"15">
          %722 = "cute.add_offset"(%618, %721) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %723 = "builtin.unrealized_conversion_cast"(%720) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %724 = "builtin.unrealized_conversion_cast"(%722) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %725 = "llvm.load"(%723) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%725, %724) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %304 = "cute.memref.load_vec"(%207) : (!memref_rmem_f32_) -> vector<16xf32>
      %305 = "cute.memref.load_vec"(%210) : (!memref_rmem_f32_) -> vector<16xf32>
      %306 = "arith.addf"(%304, %305) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%306, %213) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %307 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %308 = "cute.make_view"(%214, %307) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %309 = "cute.get_iter"(%308) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %310 = "cute.make_view"(%309) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_1
      %311 = "cute.get_layout"(%204) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %312 = "cute.static"() : () -> !cute.layout<"1:0">
      %313 = "cute.append_to_rank"(%311, %312) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %314 = "cute.make_view"(%205, %313) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %315 = "cute.get_iter"(%314) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %316 = "cute.get_layout"(%314) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %317 = "cute.get_scalars"(%316) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %318 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %319 = "cute.make_stride"(%317) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %320 = "cute.make_layout"(%318, %319) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %321 = "cute.make_view"(%315, %320) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !memref_gmem_f32_3
      %322 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %323 = "cute.make_view"(%237, %322) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %324 = "cute.get_iter"(%323) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %325 = "cute.make_view"(%324) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
      %326 = "cute.static"() : () -> !cute.layout<"1:0">
      %327 = "cute.get_iter"(%310) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %328 = "cute.get_iter"(%321) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %329 = "cute.get_layout"(%321) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %330 = "cute.append_to_rank"(%329, %326) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %331 = "cute.get_scalars"(%330) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %332 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %333 = "cute.make_stride"(%331) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %334 = "cute.make_layout"(%332, %333) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %335 = "cute.get_iter"(%325) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %336 = "cute.static"() : () -> !cute.int_tuple<"1">
      %337 = "cute.get_scalars"(%336) : (!cute.int_tuple<"1">) -> i32
      %338 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %339 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%338, %337, %339) ({
      ^bb0(%arg9: i32):
        %340 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %341 = "cute.static"() : () -> !cute.int_tuple<"0">
        %342 = "cute.add_offset"(%327, %341) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %343 = "cute.make_view"(%342, %340) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_f32_2
        %344 = "cute.get_scalars"(%334) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
        %345 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
        %346 = "cute.make_stride"(%344) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %347 = "cute.make_layout"(%345, %346) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %348 = "cute.static"() : () -> !cute.int_tuple<"0">
        %349 = "cute.add_offset"(%328, %348) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %350 = "cute.make_view"(%349, %347) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> !memref_gmem_f32_4
        %351 = "cute.static"() : () -> !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %352 = "cute.static"() : () -> !cute.int_tuple<"0">
        %353 = "cute.add_offset"(%335, %352) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %354 = "cute.make_view"(%353, %351) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4))):((0,(1,4)))">) -> !memref_rmem_i8_2
        %355 = "cute.get_iter"(%343) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %356 = "cute.get_iter"(%350) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %357 = "cute.get_layout"(%350) : (!memref_gmem_f32_4) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %358 = "cute.get_scalars"(%357) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
        %359 = "cute.get_iter"(%354) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %360 = "builtin.unrealized_conversion_cast"(%359) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %361 = "llvm.load"(%360) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %362 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %363 = "llvm.icmp"(%361, %362) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%363) ({
          %597 = "builtin.unrealized_conversion_cast"(%355) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %598 = "builtin.unrealized_conversion_cast"(%356) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %599 = "llvm.load"(%597) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%599, %598) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %364 = "cute.static"() : () -> !cute.int_tuple<"1">
        %365 = "cute.add_offset"(%359, %364) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %366 = "builtin.unrealized_conversion_cast"(%365) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %367 = "llvm.load"(%366) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %368 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %369 = "llvm.icmp"(%367, %368) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%369) ({
          %590 = "cute.static"() : () -> !cute.int_tuple<"1">
          %591 = "cute.add_offset"(%355, %590) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %592 = "cute.static"() : () -> !cute.int_tuple<"1">
          %593 = "cute.add_offset"(%356, %592) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %594 = "builtin.unrealized_conversion_cast"(%591) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %595 = "builtin.unrealized_conversion_cast"(%593) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %596 = "llvm.load"(%594) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%596, %595) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %370 = "cute.static"() : () -> !cute.int_tuple<"2">
        %371 = "cute.add_offset"(%359, %370) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %372 = "builtin.unrealized_conversion_cast"(%371) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %373 = "llvm.load"(%372) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %374 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %375 = "llvm.icmp"(%373, %374) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%375) ({
          %583 = "cute.static"() : () -> !cute.int_tuple<"2">
          %584 = "cute.add_offset"(%355, %583) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %585 = "cute.static"() : () -> !cute.int_tuple<"2">
          %586 = "cute.add_offset"(%356, %585) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %587 = "builtin.unrealized_conversion_cast"(%584) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %588 = "builtin.unrealized_conversion_cast"(%586) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %589 = "llvm.load"(%587) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%589, %588) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %376 = "cute.static"() : () -> !cute.int_tuple<"3">
        %377 = "cute.add_offset"(%359, %376) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %378 = "builtin.unrealized_conversion_cast"(%377) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %379 = "llvm.load"(%378) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %380 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %381 = "llvm.icmp"(%379, %380) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%381) ({
          %576 = "cute.static"() : () -> !cute.int_tuple<"3">
          %577 = "cute.add_offset"(%355, %576) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %578 = "cute.static"() : () -> !cute.int_tuple<"3">
          %579 = "cute.add_offset"(%356, %578) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %580 = "builtin.unrealized_conversion_cast"(%577) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %581 = "builtin.unrealized_conversion_cast"(%579) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %582 = "llvm.load"(%580) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%582, %581) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %382 = "cute.static"() : () -> !cute.int_tuple<"4">
        %383 = "cute.add_offset"(%359, %382) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %384 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %385 = "llvm.load"(%384) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %386 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %387 = "llvm.icmp"(%385, %386) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%387) ({
          %569 = "cute.static"() : () -> !cute.int_tuple<"4">
          %570 = "cute.add_offset"(%355, %569) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %571 = "cute.make_int_tuple"(%358) : (i64) -> !cute.int_tuple<"?{i64}">
          %572 = "cute.add_offset"(%356, %571) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %573 = "builtin.unrealized_conversion_cast"(%570) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %574 = "builtin.unrealized_conversion_cast"(%572) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %575 = "llvm.load"(%573) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%575, %574) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %388 = "cute.static"() : () -> !cute.int_tuple<"5">
        %389 = "cute.add_offset"(%359, %388) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %390 = "builtin.unrealized_conversion_cast"(%389) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %391 = "llvm.load"(%390) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %392 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %393 = "llvm.icmp"(%391, %392) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%393) ({
          %560 = "cute.static"() : () -> !cute.int_tuple<"5">
          %561 = "cute.add_offset"(%355, %560) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %562 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %563 = "arith.addi"(%358, %562) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %564 = "cute.make_int_tuple"(%563) : (i64) -> !cute.int_tuple<"?{i64}">
          %565 = "cute.add_offset"(%356, %564) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %566 = "builtin.unrealized_conversion_cast"(%561) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %567 = "builtin.unrealized_conversion_cast"(%565) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %568 = "llvm.load"(%566) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%568, %567) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %394 = "cute.static"() : () -> !cute.int_tuple<"6">
        %395 = "cute.add_offset"(%359, %394) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %396 = "builtin.unrealized_conversion_cast"(%395) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %397 = "llvm.load"(%396) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %398 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %399 = "llvm.icmp"(%397, %398) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%399) ({
          %551 = "cute.static"() : () -> !cute.int_tuple<"6">
          %552 = "cute.add_offset"(%355, %551) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %553 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %554 = "arith.addi"(%358, %553) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %555 = "cute.make_int_tuple"(%554) : (i64) -> !cute.int_tuple<"?{i64}">
          %556 = "cute.add_offset"(%356, %555) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %557 = "builtin.unrealized_conversion_cast"(%552) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %558 = "builtin.unrealized_conversion_cast"(%556) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %559 = "llvm.load"(%557) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%559, %558) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %400 = "cute.static"() : () -> !cute.int_tuple<"7">
        %401 = "cute.add_offset"(%359, %400) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %402 = "builtin.unrealized_conversion_cast"(%401) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %403 = "llvm.load"(%402) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %404 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %405 = "llvm.icmp"(%403, %404) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%405) ({
          %542 = "cute.static"() : () -> !cute.int_tuple<"7">
          %543 = "cute.add_offset"(%355, %542) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %544 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %545 = "arith.addi"(%358, %544) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %546 = "cute.make_int_tuple"(%545) : (i64) -> !cute.int_tuple<"?{i64}">
          %547 = "cute.add_offset"(%356, %546) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %548 = "builtin.unrealized_conversion_cast"(%543) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %549 = "builtin.unrealized_conversion_cast"(%547) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %550 = "llvm.load"(%548) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%550, %549) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %406 = "cute.static"() : () -> !cute.int_tuple<"8">
        %407 = "cute.add_offset"(%359, %406) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %408 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
        %409 = "llvm.load"(%408) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %410 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %411 = "llvm.icmp"(%409, %410) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%411) ({
          %532 = "cute.static"() : () -> !cute.int_tuple<"8">
          %533 = "cute.add_offset"(%355, %532) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %534 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %535 = "arith.muli"(%358, %534) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %536 = "cute.assume"(%535) : (i64) -> !cute.i64<divby 2>
          %537 = "cute.make_int_tuple"(%536) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %538 = "cute.add_offset"(%356, %537) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %539 = "builtin.unrealized_conversion_cast"(%533) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %540 = "builtin.unrealized_conversion_cast"(%538) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %541 = "llvm.load"(%539) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%541, %540) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %412 = "cute.static"() : () -> !cute.int_tuple<"9">
        %413 = "cute.add_offset"(%359, %412) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %414 = "builtin.unrealized_conversion_cast"(%413) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %415 = "llvm.load"(%414) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %416 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %417 = "llvm.icmp"(%415, %416) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%417) ({
          %521 = "cute.static"() : () -> !cute.int_tuple<"9">
          %522 = "cute.add_offset"(%355, %521) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %523 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %524 = "arith.muli"(%358, %523) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %525 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %526 = "arith.addi"(%524, %525) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %527 = "cute.make_int_tuple"(%526) : (i64) -> !cute.int_tuple<"?{i64}">
          %528 = "cute.add_offset"(%356, %527) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %529 = "builtin.unrealized_conversion_cast"(%522) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %530 = "builtin.unrealized_conversion_cast"(%528) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %531 = "llvm.load"(%529) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%531, %530) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %418 = "cute.static"() : () -> !cute.int_tuple<"10">
        %419 = "cute.add_offset"(%359, %418) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %420 = "builtin.unrealized_conversion_cast"(%419) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %421 = "llvm.load"(%420) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %422 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %423 = "llvm.icmp"(%421, %422) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%423) ({
          %509 = "cute.static"() : () -> !cute.int_tuple<"10">
          %510 = "cute.add_offset"(%355, %509) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %511 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %512 = "arith.muli"(%358, %511) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %513 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %514 = "arith.addi"(%512, %513) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %515 = "cute.assume"(%514) : (i64) -> !cute.i64<divby 2>
          %516 = "cute.make_int_tuple"(%515) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %517 = "cute.add_offset"(%356, %516) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %518 = "builtin.unrealized_conversion_cast"(%510) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %519 = "builtin.unrealized_conversion_cast"(%517) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %520 = "llvm.load"(%518) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%520, %519) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %424 = "cute.static"() : () -> !cute.int_tuple<"11">
        %425 = "cute.add_offset"(%359, %424) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %426 = "builtin.unrealized_conversion_cast"(%425) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %427 = "llvm.load"(%426) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %428 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %429 = "llvm.icmp"(%427, %428) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%429) ({
          %498 = "cute.static"() : () -> !cute.int_tuple<"11">
          %499 = "cute.add_offset"(%355, %498) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %500 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %501 = "arith.muli"(%358, %500) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %502 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %503 = "arith.addi"(%501, %502) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %504 = "cute.make_int_tuple"(%503) : (i64) -> !cute.int_tuple<"?{i64}">
          %505 = "cute.add_offset"(%356, %504) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %506 = "builtin.unrealized_conversion_cast"(%499) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %507 = "builtin.unrealized_conversion_cast"(%505) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %508 = "llvm.load"(%506) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%508, %507) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %430 = "cute.static"() : () -> !cute.int_tuple<"12">
        %431 = "cute.add_offset"(%359, %430) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %432 = "builtin.unrealized_conversion_cast"(%431) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %433 = "llvm.load"(%432) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %434 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %435 = "llvm.icmp"(%433, %434) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%435) ({
          %488 = "cute.static"() : () -> !cute.int_tuple<"12">
          %489 = "cute.add_offset"(%355, %488) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %490 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %491 = "arith.muli"(%358, %490) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %492 = "cute.assume"(%491) : (i64) -> !cute.i64<divby 3>
          %493 = "cute.make_int_tuple"(%492) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %494 = "cute.add_offset"(%356, %493) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %495 = "builtin.unrealized_conversion_cast"(%489) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %496 = "builtin.unrealized_conversion_cast"(%494) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %497 = "llvm.load"(%495) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%497, %496) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %436 = "cute.static"() : () -> !cute.int_tuple<"13">
        %437 = "cute.add_offset"(%359, %436) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %438 = "builtin.unrealized_conversion_cast"(%437) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %439 = "llvm.load"(%438) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %440 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %441 = "llvm.icmp"(%439, %440) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%441) ({
          %477 = "cute.static"() : () -> !cute.int_tuple<"13">
          %478 = "cute.add_offset"(%355, %477) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %479 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %480 = "arith.muli"(%358, %479) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %481 = "arith.constant"() <{value = 1 : i64}> : () -> i64
          %482 = "arith.addi"(%480, %481) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %483 = "cute.make_int_tuple"(%482) : (i64) -> !cute.int_tuple<"?{i64}">
          %484 = "cute.add_offset"(%356, %483) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %485 = "builtin.unrealized_conversion_cast"(%478) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %486 = "builtin.unrealized_conversion_cast"(%484) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %487 = "llvm.load"(%485) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%487, %486) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %442 = "cute.static"() : () -> !cute.int_tuple<"14">
        %443 = "cute.add_offset"(%359, %442) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %444 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %445 = "llvm.load"(%444) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %446 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %447 = "llvm.icmp"(%445, %446) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%447) ({
          %466 = "cute.static"() : () -> !cute.int_tuple<"14">
          %467 = "cute.add_offset"(%355, %466) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %468 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %469 = "arith.muli"(%358, %468) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %470 = "arith.constant"() <{value = 2 : i64}> : () -> i64
          %471 = "arith.addi"(%469, %470) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %472 = "cute.make_int_tuple"(%471) : (i64) -> !cute.int_tuple<"?{i64}">
          %473 = "cute.add_offset"(%356, %472) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %474 = "builtin.unrealized_conversion_cast"(%467) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %475 = "builtin.unrealized_conversion_cast"(%473) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %476 = "llvm.load"(%474) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%476, %475) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %448 = "cute.static"() : () -> !cute.int_tuple<"15">
        %449 = "cute.add_offset"(%359, %448) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %450 = "builtin.unrealized_conversion_cast"(%449) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %451 = "llvm.load"(%450) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %452 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %453 = "llvm.icmp"(%451, %452) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%453) ({
          %454 = "cute.static"() : () -> !cute.int_tuple<"15">
          %455 = "cute.add_offset"(%355, %454) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %456 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %457 = "arith.muli"(%358, %456) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %458 = "arith.constant"() <{value = 3 : i64}> : () -> i64
          %459 = "arith.addi"(%457, %458) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %460 = "cute.assume"(%459) : (i64) -> !cute.i64<divby 3>
          %461 = "cute.make_int_tuple"(%460) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %462 = "cute.add_offset"(%356, %461) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %463 = "builtin.unrealized_conversion_cast"(%455) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %464 = "builtin.unrealized_conversion_cast"(%462) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %465 = "llvm.load"(%463) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%465, %464) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_5, !memref_gmem_f32_5, !memref_gmem_f32_5) -> i32, sym_name = "cutlass_elementwise_add_tensor00644_03711_00110_04851_03515_08385_15093_00759_05930_07060_10713_18194_00944_06791_03214_06920_01900_16902_02636_10262_09792_12286_01389_04307_02417_"}> ({
  ^bb0(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %2:3 = "cute.get_scalars"(%1) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %3 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %4 = "arith.ceildivsi"(%2#0, %3) : (i32, i32) -> i32
    %5 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %6 = "arith.muli"(%2#2, %5) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %7 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %8 = "arith.ceildivsi"(%2#1, %7) : (i32, i32) -> i32
    %9 = "cute.make_shape"(%4, %8) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %10 = "cute.assume"(%6) : (i64) -> !cute.i64<divby 16>
    %11 = "cute.make_stride"(%2#2, %10) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %12 = "cute.make_layout"(%9, %11) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %13 = "cute.make_view"(%0, %12) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %14 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %15 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %16:3 = "cute.get_scalars"(%15) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %17 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %18 = "arith.ceildivsi"(%16#0, %17) : (i32, i32) -> i32
    %19 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %20 = "arith.muli"(%16#2, %19) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %21 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %22 = "arith.ceildivsi"(%16#1, %21) : (i32, i32) -> i32
    %23 = "cute.make_shape"(%18, %22) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %24 = "cute.assume"(%20) : (i64) -> !cute.i64<divby 16>
    %25 = "cute.make_stride"(%16#2, %24) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %26 = "cute.make_layout"(%23, %25) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %27 = "cute.make_view"(%14, %26) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %28 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
    %29 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %30:3 = "cute.get_scalars"(%29) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %31 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %32 = "arith.ceildivsi"(%30#0, %31) : (i32, i32) -> i32
    %33 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %34 = "arith.muli"(%30#2, %33) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %35 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %36 = "arith.ceildivsi"(%30#1, %35) : (i32, i32) -> i32
    %37 = "cute.make_shape"(%32, %36) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %38 = "cute.assume"(%34) : (i64) -> !cute.i64<divby 16>
    %39 = "cute.make_stride"(%30#2, %38) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %40 = "cute.make_layout"(%37, %39) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %41 = "cute.make_view"(%28, %40) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %42 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %43 = "cute.get_shape"(%42) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %44:2 = "cute.get_leaves"(%43) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %45 = "cute.to_int_tuple"(%44#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.to_int_tuple"(%44#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %47 = "cute.make_shape"(%45, %46) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %48 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
    %49 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
    %50 = "cute.make_layout"(%47, %49) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %51 = "cute.make_view"(%48, %50) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %52 = "cute.get_iter"(%51) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
    %53 = "cute.get_layout"(%51) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %54:2 = "cute.get_scalars"(%53) <{only_dynamic}> : (!cute.layout<"(?,?):(1@0,1@1)">) -> (i32, i32)
    %55 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %56 = "arith.ceildivsi"(%54#0, %55) : (i32, i32) -> i32
    %57 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %58 = "arith.ceildivsi"(%54#1, %57) : (i32, i32) -> i32
    %59 = "cute.make_shape"(%56, %58) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %60 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %61 = "cute.make_layout"(%59, %60) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %62 = "cute.make_view"(%52, %61) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %63 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_5) -> !cute.layout<"(?,?):(?{i64},1)">
    %64 = "cute.get_shape"(%63) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %65:2 = "cute.get_leaves"(%64) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %66 = "cute.to_int_tuple"(%65#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %67 = "cute.get_scalars"(%66) : (!cute.int_tuple<"?">) -> i32
    %68 = "cute.to_int_tuple"(%65#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %69 = "cute.get_scalars"(%68) : (!cute.int_tuple<"?">) -> i32
    %70 = "cute.get_layout"(%41) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %71 = "cute.size"(%70) <{mode = array<i32: 1>}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %72 = "cute.get_leaves"(%71) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %73 = "cute.get_scalars"(%72) : (!cute.int_tuple<"?">) -> i32
    %74 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %75 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %76 = "cuda.cast"(%75) : (i64) -> !cuda.stream
    %77 = "arith.extsi"(%74) : (i32) -> i64
    %78 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %79 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %80 = "cuda.launch_cfg.create"(%78, %79, %79, %77, %73, %79, %79, %76) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %81 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%80, %81) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %82 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%80, %82) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %83 = "cuda.launch_ex"(%80, %13, %27, %41, %62, %67, %69) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %84 = "cuda.cast"(%83) : (!cuda.result) -> i32
    "cuda.return_if_error"(%84) : (i32) -> ()
    %85 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%85) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
