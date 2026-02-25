!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %89 = "cute.static"() : () -> !cute.layout<"(4,32):(32,1)">
      %90 = "cute.static"() : () -> !cute.layout<"(4,4):(4,1)">
      %91 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %92 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %93 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %94 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %95 = "cute.deref_arith_tuple_iter"(%94) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %96:2 = "cute.get_leaves"(%95) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %97 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %98 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %99 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %100 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %101 = "cute.deref_arith_tuple_iter"(%100) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %102:2 = "cute.get_leaves"(%101) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %103 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %104 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %105 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %106 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %107 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %108 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %109 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %110 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %111 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %112 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %113 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %114 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %115 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %116 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %117 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"((_,_),?)">
      %118 = "cute.slice"(%arg3, %117) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %119 = "cute.get_iter"(%118) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %120 = "cute.get_iter"(%118) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %121 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"((_,_),?)">
      %122 = "cute.slice"(%arg4, %121) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %123 = "cute.get_iter"(%122) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %124 = "cute.get_iter"(%122) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %125 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"((_,_),?)">
      %126 = "cute.slice"(%arg5, %125) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %127 = "cute.get_iter"(%126) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %128 = "cute.get_iter"(%126) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %129 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"((_,_),?)">
      %130 = "cute.slice"(%arg6, %129) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %131 = "cute.get_iter"(%130) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %132 = "cute.deref_arith_tuple_iter"(%131) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %133:2 = "cute.get_leaves"(%132) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %134 = "cute.get_scalars"(%133#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %135 = "cute.get_scalars"(%133#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %136 = "cute.get_iter"(%130) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %137 = "cute.deref_arith_tuple_iter"(%136) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %138:2 = "cute.get_leaves"(%137) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %139 = "cute.get_scalars"(%138#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %140 = "cute.get_scalars"(%138#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %141 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %142 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %143 = "cute.raked_product"(%89, %90) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %144 = "cute.size"(%89) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %145 = "cute.get_leaves"(%144) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %146 = "cute.size"(%90) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %147 = "cute.get_leaves"(%146) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %148 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %149 = "cute.make_layout"(%148) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %150 = "cute.right_inverse"(%143) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %151 = "cute.composition"(%150, %149) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %152 = "cute.get_shape"(%143) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %153:4 = "cute.get_leaves"(%152) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %154 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %155 = "cute.tuple.product_each"(%154) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %156:2 = "cute.get_leaves"(%155) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %157 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %158 = "cute.tuple.product_each"(%157) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %159:2 = "cute.get_leaves"(%158) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %160 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %161 = "cute.make_tiled_copy"(%141) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %162 = "cute.raked_product"(%89, %90) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %163 = "cute.size"(%89) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %164 = "cute.get_leaves"(%163) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %165 = "cute.size"(%90) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %166 = "cute.get_leaves"(%165) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %167 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %168 = "cute.make_layout"(%167) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %169 = "cute.right_inverse"(%162) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %170 = "cute.composition"(%169, %168) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %171 = "cute.get_shape"(%162) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %172:4 = "cute.get_leaves"(%171) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %173 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %174 = "cute.tuple.product_each"(%173) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %175:2 = "cute.get_leaves"(%174) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %176 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %177 = "cute.tuple.product_each"(%176) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %178:2 = "cute.get_leaves"(%177) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %179 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %180 = "cute.make_tiled_copy"(%141) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %181 = "cute.raked_product"(%89, %90) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %182 = "cute.size"(%89) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %183 = "cute.get_leaves"(%182) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %184 = "cute.size"(%90) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %185 = "cute.get_leaves"(%184) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %186 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %187 = "cute.make_layout"(%186) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %188 = "cute.right_inverse"(%181) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %189 = "cute.composition"(%188, %187) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %190 = "cute.get_shape"(%181) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %191:4 = "cute.get_leaves"(%190) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %192 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %193 = "cute.tuple.product_each"(%192) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %194:2 = "cute.get_leaves"(%193) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %195 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %196 = "cute.tuple.product_each"(%195) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %197:2 = "cute.get_leaves"(%196) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %198 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %199 = "cute.make_tiled_copy"(%142) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %200 = "cute.make_coord"(%111) : (i32) -> !cute.coord<"?">
      %201 = "cute.tiled.copy.partition_S"(%161, %118, %200) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %202 = "cute.get_iter"(%201) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %203 = "cute.make_coord"(%111) : (i32) -> !cute.coord<"?">
      %204 = "cute.tiled.copy.partition_S"(%180, %122, %203) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %205 = "cute.get_iter"(%204) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %206 = "cute.make_coord"(%111) : (i32) -> !cute.coord<"?">
      %207 = "cute.tiled.copy.partition_S"(%199, %126, %206) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %208 = "cute.get_iter"(%207) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %209 = "cute.get_layout"(%201) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %210 = "cute.make_layout_like"(%209) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %211 = "cute.memref.alloca"(%210) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %212 = "cute.get_iter"(%211) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %213 = "cute.get_iter"(%211) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %214 = "cute.get_layout"(%204) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %215 = "cute.make_layout_like"(%214) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %216 = "cute.memref.alloca"(%215) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %217 = "cute.get_iter"(%216) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %218 = "cute.get_iter"(%216) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %219 = "cute.get_layout"(%207) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %220 = "cute.make_layout_like"(%219) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %221 = "cute.memref.alloca"(%220) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %222 = "cute.get_iter"(%221) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %223 = "cute.get_iter"(%221) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %224 = "cute.make_coord"(%111) : (i32) -> !cute.coord<"?">
      %225 = "cute.tiled.copy.partition_S"(%199, %130, %224) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %226 = "cute.get_iter"(%225) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %227 = "cute.deref_arith_tuple_iter"(%226) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %228:2 = "cute.get_leaves"(%227) : (!cute.int_tuple<"(?{div=4},?{div=4})">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">)
      %229 = "cute.get_scalars"(%228#0) : (!cute.int_tuple<"?{div=4}">) -> i32
      %230 = "cute.get_scalars"(%228#1) : (!cute.int_tuple<"?{div=4}">) -> i32
      %231 = "cute.get_layout"(%225) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %232 = "cute.get_shape"(%231) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %233:5 = "cute.get_leaves"(%232) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %234 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %235 = "cute.make_layout"(%234) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"((1,(4,4)),1,1)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %236 = "cute.memref.alloca"(%235) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %237 = "cute.get_iter"(%236) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %238 = "cute.get_iter"(%236) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %239 = "cute.size"(%236) <{mode = array<i32>}> : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %240 = "cute.get_leaves"(%239) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %241 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %242 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %243 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %244 = "scf.for"(%241, %242, %243, %236) ({
      ^bb0(%arg9: i32, %arg10: !memref_rmem_i8_):
        %458 = "cute.get_iter"(%arg10) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %459 = "cute.get_iter"(%arg10) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %460 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        %461 = "cute.slice"(%225, %460) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?)", "():()">
        %462 = "cute.get_iter"(%461) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %463 = "cute.deref_arith_tuple_iter"(%462) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %464:2 = "cute.get_leaves"(%463) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %465 = "cute.get_scalars"(%464#0) : (!cute.int_tuple<"?">) -> i32
        %466 = "cute.get_scalars"(%464#1) : (!cute.int_tuple<"?">) -> i32
        %467 = "cute.get_iter"(%461) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %468 = "cute.deref_arith_tuple_iter"(%467) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %469:2 = "cute.get_leaves"(%468) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %470 = "cute.get_scalars"(%469#0) : (!cute.int_tuple<"?">) -> i32
        %471 = "cute.get_scalars"(%469#1) : (!cute.int_tuple<"?">) -> i32
        %472 = "cute.get_iter"(%461) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %473 = "cute.deref_arith_tuple_iter"(%472) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %474:2 = "cute.get_leaves"(%473) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %475 = "cute.get_scalars"(%474#0) : (!cute.int_tuple<"?">) -> i32
        %476 = "cute.get_scalars"(%474#1) : (!cute.int_tuple<"?">) -> i32
        %477 = "cute.make_coord"(%474#0, %474#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %478 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %479 = "cute.elem_less"(%477, %478) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %480 = "arith.extui"(%479) : (i1) -> i8
        %481 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg10, %481, %480) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg10) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %245 = "cute.get_iter"(%244) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %246 = "cute.get_iter"(%244) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %247 = "cute.get_iter"(%244) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %248 = "cute.get_layout"(%201) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %249 = "cute.get_shape"(%248) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %250:5 = "cute.get_leaves"(%249) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %251 = "cute.get_layout"(%211) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %252 = "cute.get_shape"(%251) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %253:5 = "cute.get_leaves"(%252) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %254 = "cute.get_layout"(%201) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %255 = "cute.make_shape"() : () -> !cute.shape<"1">
      %256 = "cute.make_layout"(%255) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %257 = "cute.append_to_rank"(%254, %256) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %258 = "cute.make_view"(%202, %257) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %259 = "cute.get_iter"(%258) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %260 = "cute.get_layout"(%258) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %261 = "cute.get_shape"(%260) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %262:5 = "cute.get_leaves"(%261) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %263 = "cute.get_layout"(%258) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %264 = "cute.get_shape"(%263) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %265:5 = "cute.get_leaves"(%264) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %266 = "cute.group_modes"(%258) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %267 = "cute.get_iter"(%266) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %268 = "cute.get_iter"(%266) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %269 = "cute.get_layout"(%211) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %270 = "cute.make_shape"() : () -> !cute.shape<"1">
      %271 = "cute.make_layout"(%270) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %272 = "cute.append_to_rank"(%269, %271) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %273 = "cute.make_view"(%213, %272) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %274 = "cute.get_iter"(%273) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %275 = "cute.get_layout"(%273) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %276 = "cute.get_shape"(%275) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %277:5 = "cute.get_leaves"(%276) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %278 = "cute.get_layout"(%273) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %279 = "cute.get_shape"(%278) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %280:5 = "cute.get_leaves"(%279) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %281 = "cute.group_modes"(%273) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %282 = "cute.get_iter"(%281) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %283 = "cute.get_iter"(%281) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %284 = "cute.get_layout"(%244) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %285 = "cute.make_shape"() : () -> !cute.shape<"1">
      %286 = "cute.make_layout"(%285) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %287 = "cute.append_to_rank"(%284, %286) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %288 = "cute.make_view"(%247, %287) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %289 = "cute.get_iter"(%288) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %290 = "cute.get_layout"(%288) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %291 = "cute.get_shape"(%290) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %292:5 = "cute.get_leaves"(%291) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %293 = "cute.get_layout"(%288) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %294 = "cute.get_shape"(%293) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %295:5 = "cute.get_leaves"(%294) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %296 = "cute.group_modes"(%288) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %297 = "cute.get_iter"(%296) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %298 = "cute.get_iter"(%296) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %299 = "cute.get_layout"(%266) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %300 = "cute.get_shape"(%299) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %301:5 = "cute.get_leaves"(%300) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %302 = "cute.get_layout"(%281) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %303 = "cute.get_shape"(%302) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %304:5 = "cute.get_leaves"(%303) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %305 = "cute.size"(%266) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %306 = "cute.get_leaves"(%305) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %307 = "cute.size"(%281) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %308 = "cute.get_leaves"(%307) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%141, %266, %281, %296) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
      %309 = "cute.get_layout"(%204) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %310 = "cute.get_shape"(%309) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %311:5 = "cute.get_leaves"(%310) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %312 = "cute.get_layout"(%216) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %313 = "cute.get_shape"(%312) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %314:5 = "cute.get_leaves"(%313) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %315 = "cute.get_layout"(%204) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %316 = "cute.make_shape"() : () -> !cute.shape<"1">
      %317 = "cute.make_layout"(%316) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %318 = "cute.append_to_rank"(%315, %317) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %319 = "cute.make_view"(%205, %318) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %320 = "cute.get_iter"(%319) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %321 = "cute.get_layout"(%319) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %322 = "cute.get_shape"(%321) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %323:5 = "cute.get_leaves"(%322) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %324 = "cute.get_layout"(%319) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %325 = "cute.get_shape"(%324) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %326:5 = "cute.get_leaves"(%325) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %327 = "cute.group_modes"(%319) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %328 = "cute.get_iter"(%327) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %329 = "cute.get_iter"(%327) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %330 = "cute.get_layout"(%216) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %331 = "cute.make_shape"() : () -> !cute.shape<"1">
      %332 = "cute.make_layout"(%331) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %333 = "cute.append_to_rank"(%330, %332) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %334 = "cute.make_view"(%218, %333) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %335 = "cute.get_iter"(%334) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %336 = "cute.get_layout"(%334) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %337 = "cute.get_shape"(%336) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %338:5 = "cute.get_leaves"(%337) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %339 = "cute.get_layout"(%334) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %340 = "cute.get_shape"(%339) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %341:5 = "cute.get_leaves"(%340) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %342 = "cute.group_modes"(%334) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %343 = "cute.get_iter"(%342) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %344 = "cute.get_iter"(%342) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %345 = "cute.get_layout"(%244) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %346 = "cute.make_shape"() : () -> !cute.shape<"1">
      %347 = "cute.make_layout"(%346) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %348 = "cute.append_to_rank"(%345, %347) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %349 = "cute.make_view"(%247, %348) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %350 = "cute.get_iter"(%349) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %351 = "cute.get_layout"(%349) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %352 = "cute.get_shape"(%351) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %353:5 = "cute.get_leaves"(%352) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %354 = "cute.get_layout"(%349) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %355 = "cute.get_shape"(%354) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %356:5 = "cute.get_leaves"(%355) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %357 = "cute.group_modes"(%349) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %358 = "cute.get_iter"(%357) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %359 = "cute.get_iter"(%357) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %360 = "cute.get_layout"(%327) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %361 = "cute.get_shape"(%360) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %362:5 = "cute.get_leaves"(%361) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %363 = "cute.get_layout"(%342) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %364 = "cute.get_shape"(%363) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %365:5 = "cute.get_leaves"(%364) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %366 = "cute.size"(%327) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %367 = "cute.get_leaves"(%366) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %368 = "cute.size"(%342) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %369 = "cute.get_leaves"(%368) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%141, %327, %342, %357) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
      %370 = "cute.get_layout"(%211) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %371 = "cute.get_shape"(%370) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %372:5 = "cute.get_leaves"(%371) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %373 = "cute.memref.load_vec"(%211) : (!memref_rmem_f32_) -> vector<16xf32>
      %374 = "cute.get_layout"(%211) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %375 = "cute.get_shape"(%374) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %376:5 = "cute.get_leaves"(%375) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %377 = "cute.get_layout"(%216) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %378 = "cute.get_shape"(%377) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %379:5 = "cute.get_leaves"(%378) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %380 = "cute.memref.load_vec"(%216) : (!memref_rmem_f32_) -> vector<16xf32>
      %381 = "cute.get_layout"(%216) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %382 = "cute.get_shape"(%381) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %383:5 = "cute.get_leaves"(%382) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %384 = "arith.addf"(%373, %380) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      %385 = "cute.get_layout"(%221) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %386 = "cute.get_shape"(%385) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %387:5 = "cute.get_leaves"(%386) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %388 = "cute.get_layout"(%221) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %389 = "cute.get_shape"(%388) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %390:5 = "cute.get_leaves"(%389) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %391 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %392 = "cute.size"(%391) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %393 = "cute.get_leaves"(%392) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %394 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %395 = "cute.size"(%394) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %396 = "cute.get_leaves"(%395) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%384, %221) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %397 = "cute.get_layout"(%221) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %398 = "cute.get_shape"(%397) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %399:5 = "cute.get_leaves"(%398) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %400 = "cute.get_layout"(%207) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %401 = "cute.get_shape"(%400) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %402:5 = "cute.get_leaves"(%401) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %403 = "cute.get_layout"(%221) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %404 = "cute.make_shape"() : () -> !cute.shape<"1">
      %405 = "cute.make_layout"(%404) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %406 = "cute.append_to_rank"(%403, %405) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %407 = "cute.make_view"(%223, %406) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %408 = "cute.get_iter"(%407) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %409 = "cute.get_layout"(%407) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %410 = "cute.get_shape"(%409) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %411:5 = "cute.get_leaves"(%410) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %412 = "cute.get_layout"(%407) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %413 = "cute.get_shape"(%412) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %414:5 = "cute.get_leaves"(%413) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %415 = "cute.group_modes"(%407) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %416 = "cute.get_iter"(%415) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %417 = "cute.get_iter"(%415) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %418 = "cute.get_layout"(%207) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %419 = "cute.make_shape"() : () -> !cute.shape<"1">
      %420 = "cute.make_layout"(%419) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %421 = "cute.append_to_rank"(%418, %420) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %422 = "cute.make_view"(%208, %421) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %423 = "cute.get_iter"(%422) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %424 = "cute.get_layout"(%422) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %425 = "cute.get_shape"(%424) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %426:5 = "cute.get_leaves"(%425) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %427 = "cute.get_layout"(%422) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %428 = "cute.get_shape"(%427) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %429:5 = "cute.get_leaves"(%428) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %430 = "cute.group_modes"(%422) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %431 = "cute.get_iter"(%430) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %432 = "cute.get_iter"(%430) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %433 = "cute.get_layout"(%244) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %434 = "cute.make_shape"() : () -> !cute.shape<"1">
      %435 = "cute.make_layout"(%434) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %436 = "cute.append_to_rank"(%433, %435) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %437 = "cute.make_view"(%247, %436) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %438 = "cute.get_iter"(%437) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %439 = "cute.get_layout"(%437) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %440 = "cute.get_shape"(%439) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %441:5 = "cute.get_leaves"(%440) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %442 = "cute.get_layout"(%437) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %443 = "cute.get_shape"(%442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %444:5 = "cute.get_leaves"(%443) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %445 = "cute.group_modes"(%437) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %446 = "cute.get_iter"(%445) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %447 = "cute.get_iter"(%445) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %448 = "cute.get_layout"(%415) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %449 = "cute.get_shape"(%448) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %450:5 = "cute.get_leaves"(%449) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %451 = "cute.get_layout"(%430) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %452 = "cute.get_shape"(%451) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %453:5 = "cute.get_leaves"(%452) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %454 = "cute.size"(%415) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %455 = "cute.get_leaves"(%454) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %456 = "cute.size"(%430) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %457 = "cute.get_leaves"(%456) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%142, %415, %430, %445) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_4, !memref_gmem_f32_4, !memref_gmem_f32_4) -> i32, sym_name = "cutlass_elementwise_add_tensor00644_03711_00110_04851_03515_08385_15093_00759_05930_07060_10713_18194_00944_06791_03214_06920_01900_16902_02636_10262_09792_12286_01389_04307_02417_"}> ({
  ^bb0(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %2 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %4 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %5 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
    %6 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_4) -> !cute.layout<"(?,?):(?{i64},1)">
    %7 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_4) -> !cute.layout<"(?,?):(?{i64},1)">
    %8 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_4) -> !cute.layout<"(?,?):(?{i64},1)">
    %9 = "cute.make_shape"() : () -> !cute.shape<"(4,32)">
    %10 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
    %11 = "cute.make_ordered_layout"(%9, %10) : (!cute.shape<"(4,32)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,32):(32,1)">
    %12 = "cute.make_shape"() : () -> !cute.shape<"(4,4)">
    %13 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(1,0)">
    %14 = "cute.make_ordered_layout"(%12, %13) : (!cute.shape<"(4,4)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,4):(4,1)">
    %15 = "cute.raked_product"(%11, %14) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %16 = "cute.size"(%11) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %17 = "cute.get_leaves"(%16) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %18 = "cute.size"(%14) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %19 = "cute.get_leaves"(%18) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
    %20 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
    %21 = "cute.make_layout"(%20) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
    %22 = "cute.right_inverse"(%15) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %23 = "cute.composition"(%22, %21) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %24 = "cute.get_shape"(%15) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %25:4 = "cute.get_leaves"(%24) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
    %26 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %27 = "cute.tuple.product_each"(%26) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %28:2 = "cute.get_leaves"(%27) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
    %29 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %30 = "cute.zipped_divide"(%arg0, %29) : (!memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">) -> !memref_gmem_f32_
    %31 = "cute.get_iter"(%30) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %32 = "cute.get_iter"(%30) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %33 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %34 = "cute.zipped_divide"(%arg1, %33) : (!memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">) -> !memref_gmem_f32_
    %35 = "cute.get_iter"(%34) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %36 = "cute.get_iter"(%34) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %37 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %38 = "cute.zipped_divide"(%arg2, %37) : (!memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">) -> !memref_gmem_f32_
    %39 = "cute.get_iter"(%38) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %40 = "cute.get_iter"(%38) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %41 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_4) -> !cute.layout<"(?,?):(?{i64},1)">
    %42 = "cute.get_shape"(%41) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %43:2 = "cute.get_leaves"(%42) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %44 = "cute.to_int_tuple"(%43#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %45 = "cute.get_scalars"(%44) : (!cute.int_tuple<"?">) -> i32
    %46 = "cute.to_int_tuple"(%43#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %47 = "cute.get_scalars"(%46) : (!cute.int_tuple<"?">) -> i32
    %48 = "cute.make_shape"(%44, %46) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %49 = "cute.make_identity_tensor"(%48) : (!cute.shape<"(?,?)">) -> !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %50 = "cute.get_iter"(%49) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
    %51 = "cute.deref_arith_tuple_iter"(%50) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %52:2 = "cute.get_leaves"(%51) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %53 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
    %54 = "cute.zipped_divide"(%49, %53) : (!cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">, !cute.tile<"[16:1;128:1]">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %55 = "cute.get_iter"(%54) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
    %56 = "cute.deref_arith_tuple_iter"(%55) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %57:2 = "cute.get_leaves"(%56) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %58 = "cute.get_iter"(%54) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
    %59 = "cute.deref_arith_tuple_iter"(%58) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
    %60:2 = "cute.get_leaves"(%59) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %61 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_4) -> !cute.layout<"(?,?):(?{i64},1)">
    %62 = "cute.get_shape"(%61) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %63:2 = "cute.get_leaves"(%62) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %64 = "cute.to_int_tuple"(%63#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %65 = "cute.get_scalars"(%64) : (!cute.int_tuple<"?">) -> i32
    %66 = "cute.to_int_tuple"(%63#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %67 = "cute.get_scalars"(%66) : (!cute.int_tuple<"?">) -> i32
    %68 = "cute.size"(%38) <{mode = array<i32: 1>}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %69 = "cute.get_leaves"(%68) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %70 = "cute.get_scalars"(%69) : (!cute.int_tuple<"?">) -> i32
    %71 = "cute.size"(%23) <{mode = array<i32: 0>}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %72 = "cute.get_leaves"(%71) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %73 = "cute.get_layout"(%30) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %74 = "cute.get_layout"(%34) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %75 = "cute.get_layout"(%38) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %76 = "cute.get_layout"(%54) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %77 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %78 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %79 = "cuda.cast"(%78) : (i64) -> !cuda.stream
    %80 = "arith.extsi"(%77) : (i32) -> i64
    %81 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %82 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %83 = "cuda.launch_cfg.create"(%81, %82, %82, %80, %70, %82, %82, %79) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %84 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%83, %84) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %85 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%83, %85) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %86 = "cuda.launch_ex"(%83, %30, %34, %38, %54, %65, %67) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %87 = "cuda.cast"(%86) : (!cuda.result) -> i32
    "cuda.return_if_error"(%87) : (i32) -> ()
    %88 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%88) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
