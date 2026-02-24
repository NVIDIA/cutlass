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
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}, {}, {}, {}, {}], function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32, %arg9: !cute.layout<"(4,32):(32,1)">, %arg10: !cute.layout<"(4,4):(4,1)">):
      %89 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %90 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %91 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %92 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %93 = "cute.deref_arith_tuple_iter"(%92) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %94:2 = "cute.get_leaves"(%93) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %95 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %96 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %97 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %98 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %99 = "cute.deref_arith_tuple_iter"(%98) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %100:2 = "cute.get_leaves"(%99) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %101 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %102 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %103 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %104 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %105 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %106 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %107 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %108 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %109 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %110 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %111 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %112 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %113 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %114 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %115 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %116 = "cute.slice"(%arg3, %115) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %117 = "cute.get_iter"(%116) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %118 = "cute.get_iter"(%116) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %119 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %120 = "cute.slice"(%arg4, %119) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %121 = "cute.get_iter"(%120) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %122 = "cute.get_iter"(%120) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %123 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %124 = "cute.slice"(%arg5, %123) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %125 = "cute.get_iter"(%124) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %126 = "cute.get_iter"(%124) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %127 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %128 = "cute.slice"(%arg6, %127) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %129 = "cute.get_iter"(%128) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %130 = "cute.deref_arith_tuple_iter"(%129) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %131:2 = "cute.get_leaves"(%130) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %132 = "cute.get_scalars"(%131#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %133 = "cute.get_scalars"(%131#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %134 = "cute.get_iter"(%128) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %135 = "cute.deref_arith_tuple_iter"(%134) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %136:2 = "cute.get_leaves"(%135) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %137 = "cute.get_scalars"(%136#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %138 = "cute.get_scalars"(%136#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %139 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %140 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %141 = "cute.raked_product"(%arg9, %arg10) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %142 = "cute.size"(%arg9) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %143 = "cute.get_leaves"(%142) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %144 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %145 = "cute.get_leaves"(%144) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %146 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %147 = "cute.make_layout"(%146) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %148 = "cute.right_inverse"(%141) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %149 = "cute.composition"(%148, %147) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %150 = "cute.get_shape"(%141) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %151:4 = "cute.get_leaves"(%150) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %152 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %153 = "cute.tuple.product_each"(%152) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %154:2 = "cute.get_leaves"(%153) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %155 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %156 = "cute.tuple.product_each"(%155) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %157:2 = "cute.get_leaves"(%156) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %158 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %159 = "cute.make_tiled_copy"(%139) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %160 = "cute.raked_product"(%arg9, %arg10) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %161 = "cute.size"(%arg9) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %162 = "cute.get_leaves"(%161) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %163 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %164 = "cute.get_leaves"(%163) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %165 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %166 = "cute.make_layout"(%165) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %167 = "cute.right_inverse"(%160) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %168 = "cute.composition"(%167, %166) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %169 = "cute.get_shape"(%160) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %170:4 = "cute.get_leaves"(%169) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %171 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %172 = "cute.tuple.product_each"(%171) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %173:2 = "cute.get_leaves"(%172) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %174 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %175 = "cute.tuple.product_each"(%174) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %176:2 = "cute.get_leaves"(%175) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %177 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %178 = "cute.make_tiled_copy"(%139) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %179 = "cute.raked_product"(%arg9, %arg10) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %180 = "cute.size"(%arg9) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %181 = "cute.get_leaves"(%180) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %182 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %183 = "cute.get_leaves"(%182) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %184 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %185 = "cute.make_layout"(%184) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %186 = "cute.right_inverse"(%179) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %187 = "cute.composition"(%186, %185) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %188 = "cute.get_shape"(%179) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %189:4 = "cute.get_leaves"(%188) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %190 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %191 = "cute.tuple.product_each"(%190) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %192:2 = "cute.get_leaves"(%191) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %193 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %194 = "cute.tuple.product_each"(%193) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %195:2 = "cute.get_leaves"(%194) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %196 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %197 = "cute.make_tiled_copy"(%140) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %198 = "cute.make_coord"(%109) : (i32) -> !cute.coord<"?">
      %199 = "cute.tiled.copy.partition_S"(%159, %116, %198) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %200 = "cute.get_iter"(%199) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %201 = "cute.make_coord"(%109) : (i32) -> !cute.coord<"?">
      %202 = "cute.tiled.copy.partition_S"(%178, %120, %201) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %203 = "cute.get_iter"(%202) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %204 = "cute.make_coord"(%109) : (i32) -> !cute.coord<"?">
      %205 = "cute.tiled.copy.partition_S"(%197, %124, %204) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %206 = "cute.get_iter"(%205) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %207 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %208 = "cute.make_layout_like"(%207) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %209 = "cute.memref.alloca"(%208) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %210 = "cute.get_iter"(%209) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %211 = "cute.get_iter"(%209) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %212 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %213 = "cute.make_layout_like"(%212) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %214 = "cute.memref.alloca"(%213) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %215 = "cute.get_iter"(%214) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %216 = "cute.get_iter"(%214) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %217 = "cute.get_layout"(%205) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %218 = "cute.make_layout_like"(%217) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %219 = "cute.memref.alloca"(%218) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %220 = "cute.get_iter"(%219) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %221 = "cute.get_iter"(%219) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %222 = "cute.make_coord"(%109) : (i32) -> !cute.coord<"?">
      %223 = "cute.tiled.copy.partition_S"(%197, %128, %222) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %224 = "cute.get_iter"(%223) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %225 = "cute.deref_arith_tuple_iter"(%224) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %226:2 = "cute.get_leaves"(%225) : (!cute.int_tuple<"(?{div=4},?{div=4})">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">)
      %227 = "cute.get_scalars"(%226#0) : (!cute.int_tuple<"?{div=4}">) -> i32
      %228 = "cute.get_scalars"(%226#1) : (!cute.int_tuple<"?{div=4}">) -> i32
      %229 = "cute.get_layout"(%223) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %230 = "cute.get_shape"(%229) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %231:5 = "cute.get_leaves"(%230) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %232 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %233 = "cute.make_layout"(%232) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"((1,(4,4)),1,1)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %234 = "cute.memref.alloca"(%233) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %235 = "cute.get_iter"(%234) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %236 = "cute.get_iter"(%234) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %237 = "cute.size"(%234) <{mode = array<i32>}> : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %238 = "cute.get_leaves"(%237) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %239 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %240 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %241 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %242 = "scf.for"(%239, %240, %241, %234) ({
      ^bb0(%arg11: i32, %arg12: !memref_rmem_i8_):
        %456 = "cute.get_iter"(%arg12) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %457 = "cute.get_iter"(%arg12) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %458 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"?">
        %459 = "cute.slice"(%223, %458) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?)", "():()">
        %460 = "cute.get_iter"(%459) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %461 = "cute.deref_arith_tuple_iter"(%460) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %462:2 = "cute.get_leaves"(%461) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %463 = "cute.get_scalars"(%462#0) : (!cute.int_tuple<"?">) -> i32
        %464 = "cute.get_scalars"(%462#1) : (!cute.int_tuple<"?">) -> i32
        %465 = "cute.get_iter"(%459) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %466 = "cute.deref_arith_tuple_iter"(%465) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %467:2 = "cute.get_leaves"(%466) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %468 = "cute.get_scalars"(%467#0) : (!cute.int_tuple<"?">) -> i32
        %469 = "cute.get_scalars"(%467#1) : (!cute.int_tuple<"?">) -> i32
        %470 = "cute.get_iter"(%459) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %471 = "cute.deref_arith_tuple_iter"(%470) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %472:2 = "cute.get_leaves"(%471) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %473 = "cute.get_scalars"(%472#0) : (!cute.int_tuple<"?">) -> i32
        %474 = "cute.get_scalars"(%472#1) : (!cute.int_tuple<"?">) -> i32
        %475 = "cute.make_coord"(%472#0, %472#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %476 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %477 = "cute.elem_less"(%475, %476) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %478 = "arith.extui"(%477) : (i1) -> i8
        %479 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg12, %479, %478) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg12) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %243 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %244 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %245 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %246 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %247 = "cute.get_shape"(%246) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %248:5 = "cute.get_leaves"(%247) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %249 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %250 = "cute.get_shape"(%249) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %251:5 = "cute.get_leaves"(%250) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %252 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %253 = "cute.make_shape"() : () -> !cute.shape<"1">
      %254 = "cute.make_layout"(%253) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %255 = "cute.append_to_rank"(%252, %254) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %256 = "cute.make_view"(%200, %255) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %257 = "cute.get_iter"(%256) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %258 = "cute.get_layout"(%256) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %259 = "cute.get_shape"(%258) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %260:5 = "cute.get_leaves"(%259) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %261 = "cute.get_layout"(%256) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %262 = "cute.get_shape"(%261) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %263:5 = "cute.get_leaves"(%262) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %264 = "cute.group_modes"(%256) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %265 = "cute.get_iter"(%264) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %266 = "cute.get_iter"(%264) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %267 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %268 = "cute.make_shape"() : () -> !cute.shape<"1">
      %269 = "cute.make_layout"(%268) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %270 = "cute.append_to_rank"(%267, %269) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %271 = "cute.make_view"(%211, %270) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %272 = "cute.get_iter"(%271) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %273 = "cute.get_layout"(%271) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %274 = "cute.get_shape"(%273) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %275:5 = "cute.get_leaves"(%274) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %276 = "cute.get_layout"(%271) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %277 = "cute.get_shape"(%276) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %278:5 = "cute.get_leaves"(%277) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %279 = "cute.group_modes"(%271) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %280 = "cute.get_iter"(%279) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %281 = "cute.get_iter"(%279) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %282 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %283 = "cute.make_shape"() : () -> !cute.shape<"1">
      %284 = "cute.make_layout"(%283) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %285 = "cute.append_to_rank"(%282, %284) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %286 = "cute.make_view"(%245, %285) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %287 = "cute.get_iter"(%286) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %288 = "cute.get_layout"(%286) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %289 = "cute.get_shape"(%288) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %290:5 = "cute.get_leaves"(%289) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %291 = "cute.get_layout"(%286) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %292 = "cute.get_shape"(%291) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %293:5 = "cute.get_leaves"(%292) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %294 = "cute.group_modes"(%286) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %295 = "cute.get_iter"(%294) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %296 = "cute.get_iter"(%294) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %297 = "cute.get_layout"(%264) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %298 = "cute.get_shape"(%297) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %299:5 = "cute.get_leaves"(%298) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %300 = "cute.get_layout"(%279) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %301 = "cute.get_shape"(%300) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %302:5 = "cute.get_leaves"(%301) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %303 = "cute.size"(%264) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %304 = "cute.get_leaves"(%303) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %305 = "cute.size"(%279) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %306 = "cute.get_leaves"(%305) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%139, %264, %279, %294) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
      %307 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %308 = "cute.get_shape"(%307) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %309:5 = "cute.get_leaves"(%308) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %310 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %311 = "cute.get_shape"(%310) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %312:5 = "cute.get_leaves"(%311) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %313 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %314 = "cute.make_shape"() : () -> !cute.shape<"1">
      %315 = "cute.make_layout"(%314) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %316 = "cute.append_to_rank"(%313, %315) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %317 = "cute.make_view"(%203, %316) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %318 = "cute.get_iter"(%317) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %319 = "cute.get_layout"(%317) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %320 = "cute.get_shape"(%319) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %321:5 = "cute.get_leaves"(%320) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %322 = "cute.get_layout"(%317) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %323 = "cute.get_shape"(%322) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %324:5 = "cute.get_leaves"(%323) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %325 = "cute.group_modes"(%317) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %326 = "cute.get_iter"(%325) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %327 = "cute.get_iter"(%325) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %328 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %329 = "cute.make_shape"() : () -> !cute.shape<"1">
      %330 = "cute.make_layout"(%329) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %331 = "cute.append_to_rank"(%328, %330) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %332 = "cute.make_view"(%216, %331) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %333 = "cute.get_iter"(%332) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %334 = "cute.get_layout"(%332) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %335 = "cute.get_shape"(%334) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %336:5 = "cute.get_leaves"(%335) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %337 = "cute.get_layout"(%332) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %338 = "cute.get_shape"(%337) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %339:5 = "cute.get_leaves"(%338) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %340 = "cute.group_modes"(%332) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %341 = "cute.get_iter"(%340) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %342 = "cute.get_iter"(%340) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %343 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %344 = "cute.make_shape"() : () -> !cute.shape<"1">
      %345 = "cute.make_layout"(%344) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %346 = "cute.append_to_rank"(%343, %345) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %347 = "cute.make_view"(%245, %346) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %348 = "cute.get_iter"(%347) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %349 = "cute.get_layout"(%347) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %350 = "cute.get_shape"(%349) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %351:5 = "cute.get_leaves"(%350) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %352 = "cute.get_layout"(%347) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %353 = "cute.get_shape"(%352) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %354:5 = "cute.get_leaves"(%353) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %355 = "cute.group_modes"(%347) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %356 = "cute.get_iter"(%355) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %357 = "cute.get_iter"(%355) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %358 = "cute.get_layout"(%325) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %359 = "cute.get_shape"(%358) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %360:5 = "cute.get_leaves"(%359) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %361 = "cute.get_layout"(%340) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %362 = "cute.get_shape"(%361) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %363:5 = "cute.get_leaves"(%362) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %364 = "cute.size"(%325) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %365 = "cute.get_leaves"(%364) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %366 = "cute.size"(%340) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %367 = "cute.get_leaves"(%366) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%139, %325, %340, %355) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
      %368 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %369 = "cute.get_shape"(%368) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %370:5 = "cute.get_leaves"(%369) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %371 = "cute.memref.load_vec"(%209) : (!memref_rmem_f32_) -> vector<16xf32>
      %372 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %373 = "cute.get_shape"(%372) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %374:5 = "cute.get_leaves"(%373) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %375 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %376 = "cute.get_shape"(%375) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %377:5 = "cute.get_leaves"(%376) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %378 = "cute.memref.load_vec"(%214) : (!memref_rmem_f32_) -> vector<16xf32>
      %379 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %380 = "cute.get_shape"(%379) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %381:5 = "cute.get_leaves"(%380) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %382 = "arith.addf"(%371, %378) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      %383 = "cute.get_layout"(%219) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %384 = "cute.get_shape"(%383) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %385:5 = "cute.get_leaves"(%384) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %386 = "cute.get_layout"(%219) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %387 = "cute.get_shape"(%386) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %388:5 = "cute.get_leaves"(%387) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %389 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %390 = "cute.size"(%389) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %391 = "cute.get_leaves"(%390) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %392 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %393 = "cute.size"(%392) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %394 = "cute.get_leaves"(%393) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%382, %219) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %395 = "cute.get_layout"(%219) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %396 = "cute.get_shape"(%395) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %397:5 = "cute.get_leaves"(%396) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %398 = "cute.get_layout"(%205) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %399 = "cute.get_shape"(%398) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %400:5 = "cute.get_leaves"(%399) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %401 = "cute.get_layout"(%219) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %402 = "cute.make_shape"() : () -> !cute.shape<"1">
      %403 = "cute.make_layout"(%402) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %404 = "cute.append_to_rank"(%401, %403) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %405 = "cute.make_view"(%221, %404) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %406 = "cute.get_iter"(%405) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %407 = "cute.get_layout"(%405) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %408 = "cute.get_shape"(%407) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %409:5 = "cute.get_leaves"(%408) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %410 = "cute.get_layout"(%405) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %411 = "cute.get_shape"(%410) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %412:5 = "cute.get_leaves"(%411) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %413 = "cute.group_modes"(%405) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %414 = "cute.get_iter"(%413) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %415 = "cute.get_iter"(%413) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %416 = "cute.get_layout"(%205) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %417 = "cute.make_shape"() : () -> !cute.shape<"1">
      %418 = "cute.make_layout"(%417) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %419 = "cute.append_to_rank"(%416, %418) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %420 = "cute.make_view"(%206, %419) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %421 = "cute.get_iter"(%420) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %422 = "cute.get_layout"(%420) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %423 = "cute.get_shape"(%422) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %424:5 = "cute.get_leaves"(%423) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %425 = "cute.get_layout"(%420) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %426 = "cute.get_shape"(%425) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %427:5 = "cute.get_leaves"(%426) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %428 = "cute.group_modes"(%420) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %429 = "cute.get_iter"(%428) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %430 = "cute.get_iter"(%428) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %431 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %432 = "cute.make_shape"() : () -> !cute.shape<"1">
      %433 = "cute.make_layout"(%432) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %434 = "cute.append_to_rank"(%431, %433) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %435 = "cute.make_view"(%245, %434) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %436 = "cute.get_iter"(%435) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %437 = "cute.get_layout"(%435) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %438 = "cute.get_shape"(%437) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %439:5 = "cute.get_leaves"(%438) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %440 = "cute.get_layout"(%435) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %441 = "cute.get_shape"(%440) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %442:5 = "cute.get_leaves"(%441) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %443 = "cute.group_modes"(%435) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %444 = "cute.get_iter"(%443) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %445 = "cute.get_iter"(%443) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %446 = "cute.get_layout"(%413) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %447 = "cute.get_shape"(%446) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %448:5 = "cute.get_leaves"(%447) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %449 = "cute.get_layout"(%428) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %450 = "cute.get_shape"(%449) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %451:5 = "cute.get_leaves"(%450) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %452 = "cute.size"(%413) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %453 = "cute.get_leaves"(%452) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %454 = "cute.size"(%428) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %455 = "cute.get_leaves"(%454) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%140, %413, %428, %443) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1) -> ()
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
    %86 = "cuda.launch_ex"(%83, %30, %34, %38, %54, %65, %67, %11, %14) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cuda.result
    %87 = "cuda.cast"(%86) : (!cuda.result) -> i32
    "cuda.return_if_error"(%87) : (i32) -> ()
    %88 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%88) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
