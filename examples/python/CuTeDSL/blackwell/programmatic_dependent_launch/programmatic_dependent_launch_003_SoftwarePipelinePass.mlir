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
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !memref_gmem_f32_, %arg7: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg8: i32, %arg9: i32):
      %87 = "cute.static"() : () -> !cute.layout<"(4,32):(32,1)">
      %88 = "cute.static"() : () -> !cute.layout<"(4,4):(4,1)">
      %89 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %90 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %91 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %92 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %93 = "cute.deref_arith_tuple_iter"(%92) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %94:2 = "cute.get_leaves"(%93) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %95 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %96 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %97 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %98 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %99 = "cute.deref_arith_tuple_iter"(%98) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %100:2 = "cute.get_leaves"(%99) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %101 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %102 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %103 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %104 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %105 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %106 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %107 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %108 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %109 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %110 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %111 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %112 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %113 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %114 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %115 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %116 = "cute.slice"(%arg4, %115) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %117 = "cute.get_iter"(%116) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %118 = "cute.get_iter"(%116) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %119 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %120 = "cute.slice"(%arg5, %119) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %121 = "cute.get_iter"(%120) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %122 = "cute.get_iter"(%120) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %123 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %124 = "cute.slice"(%arg6, %123) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %125 = "cute.get_iter"(%124) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %126 = "cute.get_iter"(%124) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %127 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"((_,_),?)">
      %128 = "cute.slice"(%arg7, %127) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
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
      %141 = "cute.raked_product"(%87, %88) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %142 = "cute.size"(%87) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %143 = "cute.get_leaves"(%142) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %144 = "cute.size"(%88) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
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
      %160 = "cute.raked_product"(%87, %88) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %161 = "cute.size"(%87) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %162 = "cute.get_leaves"(%161) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %163 = "cute.size"(%88) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
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
      %179 = "cute.raked_product"(%87, %88) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %180 = "cute.size"(%87) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %181 = "cute.get_leaves"(%180) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %182 = "cute.size"(%88) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
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
      ^bb0(%arg17: i32, %arg18: !memref_rmem_i8_):
        %602 = "cute.get_iter"(%arg18) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %603 = "cute.get_iter"(%arg18) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %604 = "cute.make_coord"(%arg17) : (i32) -> !cute.coord<"?">
        %605 = "cute.slice"(%223, %604) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?)", "():()">
        %606 = "cute.get_iter"(%605) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %607 = "cute.deref_arith_tuple_iter"(%606) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %608:2 = "cute.get_leaves"(%607) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %609 = "cute.get_scalars"(%608#0) : (!cute.int_tuple<"?">) -> i32
        %610 = "cute.get_scalars"(%608#1) : (!cute.int_tuple<"?">) -> i32
        %611 = "cute.get_iter"(%605) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %612 = "cute.deref_arith_tuple_iter"(%611) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %613:2 = "cute.get_leaves"(%612) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %614 = "cute.get_scalars"(%613#0) : (!cute.int_tuple<"?">) -> i32
        %615 = "cute.get_scalars"(%613#1) : (!cute.int_tuple<"?">) -> i32
        %616 = "cute.get_iter"(%605) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %617 = "cute.deref_arith_tuple_iter"(%616) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %618:2 = "cute.get_leaves"(%617) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %619 = "cute.get_scalars"(%618#0) : (!cute.int_tuple<"?">) -> i32
        %620 = "cute.get_scalars"(%618#1) : (!cute.int_tuple<"?">) -> i32
        %621 = "cute.make_coord"(%618#0, %618#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %622 = "cute.make_coord"(%arg8, %arg9) : (i32, i32) -> !cute.coord<"(?,?)">
        %623 = "cute.elem_less"(%621, %622) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %624 = "arith.extui"(%623) : (i1) -> i8
        %625 = "cute.make_coord"(%arg17) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg18, %625, %624) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg18) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %243 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %244 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %245 = "cute.get_iter"(%242) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %246 = "arith.constant"() <{value = false}> : () -> i1
      "scf.if"(%246) ({
        %477 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %478 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %479 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%477, %478, %479) ({
        ^bb0(%arg16: i32):
          %480 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %481 = "cute.get_shape"(%480) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %482:5 = "cute.get_leaves"(%481) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %483 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %484 = "cute.get_shape"(%483) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %485:5 = "cute.get_leaves"(%484) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %486 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %487 = "cute.make_shape"() : () -> !cute.shape<"1">
          %488 = "cute.make_layout"(%487) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %489 = "cute.append_to_rank"(%486, %488) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %490 = "cute.make_view"(%200, %489) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %491 = "cute.get_iter"(%490) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %492 = "cute.get_layout"(%490) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %493 = "cute.get_shape"(%492) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %494:5 = "cute.get_leaves"(%493) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %495 = "cute.get_layout"(%490) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %496 = "cute.get_shape"(%495) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %497:5 = "cute.get_leaves"(%496) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %498 = "cute.group_modes"(%490) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %499 = "cute.get_iter"(%498) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %500 = "cute.get_iter"(%498) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %501 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %502 = "cute.make_shape"() : () -> !cute.shape<"1">
          %503 = "cute.make_layout"(%502) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %504 = "cute.append_to_rank"(%501, %503) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %505 = "cute.make_view"(%211, %504) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %506 = "cute.get_iter"(%505) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %507 = "cute.get_layout"(%505) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %508 = "cute.get_shape"(%507) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %509:5 = "cute.get_leaves"(%508) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %510 = "cute.get_layout"(%505) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %511 = "cute.get_shape"(%510) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %512:5 = "cute.get_leaves"(%511) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %513 = "cute.group_modes"(%505) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %514 = "cute.get_iter"(%513) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %515 = "cute.get_iter"(%513) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %516 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %517 = "cute.make_shape"() : () -> !cute.shape<"1">
          %518 = "cute.make_layout"(%517) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %519 = "cute.append_to_rank"(%516, %518) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %520 = "cute.make_view"(%245, %519) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %521 = "cute.get_iter"(%520) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %522 = "cute.get_layout"(%520) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %523 = "cute.get_shape"(%522) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %524:5 = "cute.get_leaves"(%523) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %525 = "cute.get_layout"(%520) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %526 = "cute.get_shape"(%525) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %527:5 = "cute.get_leaves"(%526) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %528 = "cute.group_modes"(%520) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %529 = "cute.get_iter"(%528) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %530 = "cute.get_iter"(%528) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %531 = "cute.get_layout"(%498) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %532 = "cute.get_shape"(%531) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %533:5 = "cute.get_leaves"(%532) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %534 = "cute.get_layout"(%513) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %535 = "cute.get_shape"(%534) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %536:5 = "cute.get_leaves"(%535) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %537 = "cute.size"(%498) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %538 = "cute.get_leaves"(%537) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %539 = "cute.size"(%513) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %540 = "cute.get_leaves"(%539) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%139, %498, %513, %528) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          %541 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %542 = "cute.get_shape"(%541) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %543:5 = "cute.get_leaves"(%542) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %544 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %545 = "cute.get_shape"(%544) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %546:5 = "cute.get_leaves"(%545) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %547 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %548 = "cute.make_shape"() : () -> !cute.shape<"1">
          %549 = "cute.make_layout"(%548) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %550 = "cute.append_to_rank"(%547, %549) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %551 = "cute.make_view"(%203, %550) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %552 = "cute.get_iter"(%551) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %553 = "cute.get_layout"(%551) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %554 = "cute.get_shape"(%553) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %555:5 = "cute.get_leaves"(%554) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %556 = "cute.get_layout"(%551) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %557 = "cute.get_shape"(%556) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %558:5 = "cute.get_leaves"(%557) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %559 = "cute.group_modes"(%551) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %560 = "cute.get_iter"(%559) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %561 = "cute.get_iter"(%559) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %562 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %563 = "cute.make_shape"() : () -> !cute.shape<"1">
          %564 = "cute.make_layout"(%563) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %565 = "cute.append_to_rank"(%562, %564) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %566 = "cute.make_view"(%216, %565) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %567 = "cute.get_iter"(%566) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %568 = "cute.get_layout"(%566) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %569 = "cute.get_shape"(%568) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %570:5 = "cute.get_leaves"(%569) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %571 = "cute.get_layout"(%566) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %572 = "cute.get_shape"(%571) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %573:5 = "cute.get_leaves"(%572) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %574 = "cute.group_modes"(%566) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %575 = "cute.get_iter"(%574) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %576 = "cute.get_iter"(%574) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %577 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %578 = "cute.make_shape"() : () -> !cute.shape<"1">
          %579 = "cute.make_layout"(%578) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %580 = "cute.append_to_rank"(%577, %579) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %581 = "cute.make_view"(%245, %580) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %582 = "cute.get_iter"(%581) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %583 = "cute.get_layout"(%581) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %584 = "cute.get_shape"(%583) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %585:5 = "cute.get_leaves"(%584) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %586 = "cute.get_layout"(%581) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %587 = "cute.get_shape"(%586) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %588:5 = "cute.get_leaves"(%587) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %589 = "cute.group_modes"(%581) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %590 = "cute.get_iter"(%589) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %591 = "cute.get_iter"(%589) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %592 = "cute.get_layout"(%559) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %593 = "cute.get_shape"(%592) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %594:5 = "cute.get_leaves"(%593) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %595 = "cute.get_layout"(%574) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %596 = "cute.get_shape"(%595) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %597:5 = "cute.get_leaves"(%596) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %598 = "cute.size"(%559) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %599 = "cute.get_leaves"(%598) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %600 = "cute.size"(%574) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %601 = "cute.get_leaves"(%600) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%139, %559, %574, %589) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.launch_dependents;", constraints = "", has_side_effects}> : () -> ()
        "scf.yield"() : () -> ()
      }, {
        %352 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %353 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %354 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%352, %353, %354) ({
        ^bb0(%arg15: i32):
          %416 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %417 = "cute.get_shape"(%416) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %418:5 = "cute.get_leaves"(%417) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %419 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %420 = "cute.get_shape"(%419) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %421:5 = "cute.get_leaves"(%420) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %422 = "cute.get_layout"(%202) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %423 = "cute.make_shape"() : () -> !cute.shape<"1">
          %424 = "cute.make_layout"(%423) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %425 = "cute.append_to_rank"(%422, %424) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %426 = "cute.make_view"(%203, %425) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %427 = "cute.get_iter"(%426) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %428 = "cute.get_layout"(%426) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %429 = "cute.get_shape"(%428) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %430:5 = "cute.get_leaves"(%429) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %431 = "cute.get_layout"(%426) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %432 = "cute.get_shape"(%431) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %433:5 = "cute.get_leaves"(%432) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %434 = "cute.group_modes"(%426) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %435 = "cute.get_iter"(%434) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %436 = "cute.get_iter"(%434) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %437 = "cute.get_layout"(%214) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %438 = "cute.make_shape"() : () -> !cute.shape<"1">
          %439 = "cute.make_layout"(%438) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %440 = "cute.append_to_rank"(%437, %439) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %441 = "cute.make_view"(%216, %440) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %442 = "cute.get_iter"(%441) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %443 = "cute.get_layout"(%441) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %444 = "cute.get_shape"(%443) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %445:5 = "cute.get_leaves"(%444) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %446 = "cute.get_layout"(%441) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %447 = "cute.get_shape"(%446) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %448:5 = "cute.get_leaves"(%447) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %449 = "cute.group_modes"(%441) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %450 = "cute.get_iter"(%449) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %451 = "cute.get_iter"(%449) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %452 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %453 = "cute.make_shape"() : () -> !cute.shape<"1">
          %454 = "cute.make_layout"(%453) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %455 = "cute.append_to_rank"(%452, %454) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %456 = "cute.make_view"(%245, %455) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %457 = "cute.get_iter"(%456) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %458 = "cute.get_layout"(%456) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %459 = "cute.get_shape"(%458) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %460:5 = "cute.get_leaves"(%459) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %461 = "cute.get_layout"(%456) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %462 = "cute.get_shape"(%461) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %463:5 = "cute.get_leaves"(%462) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %464 = "cute.group_modes"(%456) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %465 = "cute.get_iter"(%464) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %466 = "cute.get_iter"(%464) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %467 = "cute.get_layout"(%434) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %468 = "cute.get_shape"(%467) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %469:5 = "cute.get_leaves"(%468) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %470 = "cute.get_layout"(%449) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %471 = "cute.get_shape"(%470) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %472:5 = "cute.get_leaves"(%471) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %473 = "cute.size"(%434) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %474 = "cute.get_leaves"(%473) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %475 = "cute.size"(%449) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %476 = "cute.get_leaves"(%475) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%139, %434, %449, %464) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.wait;", constraints = "", has_side_effects}> : () -> ()
        "scf.for"(%352, %353, %354) ({
        ^bb0(%arg14: i32):
          %355 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %356 = "cute.get_shape"(%355) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %357:5 = "cute.get_leaves"(%356) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %358 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %359 = "cute.get_shape"(%358) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %360:5 = "cute.get_leaves"(%359) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %361 = "cute.get_layout"(%199) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %362 = "cute.make_shape"() : () -> !cute.shape<"1">
          %363 = "cute.make_layout"(%362) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %364 = "cute.append_to_rank"(%361, %363) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %365 = "cute.make_view"(%200, %364) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %366 = "cute.get_iter"(%365) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %367 = "cute.get_layout"(%365) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %368 = "cute.get_shape"(%367) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %369:5 = "cute.get_leaves"(%368) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %370 = "cute.get_layout"(%365) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %371 = "cute.get_shape"(%370) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %372:5 = "cute.get_leaves"(%371) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %373 = "cute.group_modes"(%365) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %374 = "cute.get_iter"(%373) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %375 = "cute.get_iter"(%373) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %376 = "cute.get_layout"(%209) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %377 = "cute.make_shape"() : () -> !cute.shape<"1">
          %378 = "cute.make_layout"(%377) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %379 = "cute.append_to_rank"(%376, %378) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %380 = "cute.make_view"(%211, %379) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %381 = "cute.get_iter"(%380) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %382 = "cute.get_layout"(%380) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %383 = "cute.get_shape"(%382) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %384:5 = "cute.get_leaves"(%383) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %385 = "cute.get_layout"(%380) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %386 = "cute.get_shape"(%385) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %387:5 = "cute.get_leaves"(%386) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %388 = "cute.group_modes"(%380) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %389 = "cute.get_iter"(%388) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %390 = "cute.get_iter"(%388) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %391 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %392 = "cute.make_shape"() : () -> !cute.shape<"1">
          %393 = "cute.make_layout"(%392) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %394 = "cute.append_to_rank"(%391, %393) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %395 = "cute.make_view"(%245, %394) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %396 = "cute.get_iter"(%395) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %397 = "cute.get_layout"(%395) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %398 = "cute.get_shape"(%397) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %399:5 = "cute.get_leaves"(%398) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %400 = "cute.get_layout"(%395) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %401 = "cute.get_shape"(%400) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %402:5 = "cute.get_leaves"(%401) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %403 = "cute.group_modes"(%395) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %404 = "cute.get_iter"(%403) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %405 = "cute.get_iter"(%403) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %406 = "cute.get_layout"(%373) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %407 = "cute.get_shape"(%406) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %408:5 = "cute.get_leaves"(%407) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %409 = "cute.get_layout"(%388) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %410 = "cute.get_shape"(%409) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %411:5 = "cute.get_leaves"(%410) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %412 = "cute.size"(%373) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %413 = "cute.get_leaves"(%412) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %414 = "cute.size"(%388) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %415 = "cute.get_leaves"(%414) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%139, %373, %388, %403) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %247 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %248:3 = "scf.for"(%239, %247, %241, %209, %214, %219) ({
      ^bb0(%arg10: i32, %arg11: !memref_rmem_f32_, %arg12: !memref_rmem_f32_, %arg13: !memref_rmem_f32_):
        %319 = "cute.get_iter"(%arg11) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %320 = "cute.get_iter"(%arg12) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %321 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %322 = "cute.get_iter"(%arg11) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %323 = "cute.get_iter"(%arg12) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %324 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %325 = "cute.get_layout"(%arg11) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %326 = "cute.get_shape"(%325) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %327:5 = "cute.get_leaves"(%326) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %328 = "cute.memref.load_vec"(%arg11) : (!memref_rmem_f32_) -> vector<16xf32>
        %329 = "cute.get_layout"(%arg11) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %330 = "cute.get_shape"(%329) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %331:5 = "cute.get_leaves"(%330) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %332 = "cute.get_layout"(%arg12) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %333 = "cute.get_shape"(%332) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %334:5 = "cute.get_leaves"(%333) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %335 = "cute.memref.load_vec"(%arg12) : (!memref_rmem_f32_) -> vector<16xf32>
        %336 = "cute.get_layout"(%arg12) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %337 = "cute.get_shape"(%336) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %338:5 = "cute.get_leaves"(%337) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %339 = "arith.addf"(%328, %335) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
        %340 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %341 = "cute.get_shape"(%340) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %342:5 = "cute.get_leaves"(%341) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %343 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %344 = "cute.get_shape"(%343) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %345:5 = "cute.get_leaves"(%344) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %346 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %347 = "cute.size"(%346) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %348 = "cute.get_leaves"(%347) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        %349 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %350 = "cute.size"(%349) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %351 = "cute.get_leaves"(%350) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        "cute.memref.store_vec"(%339, %arg13) : (vector<16xf32>, !memref_rmem_f32_) -> ()
        "scf.yield"(%arg11, %arg12, %arg13) : (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> ()
      }) : (i32, i32, i32, !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)
      %249 = "cute.get_iter"(%248#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %250 = "cute.get_iter"(%248#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %251 = "cute.get_iter"(%248#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %252 = "cute.get_iter"(%248#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %253 = "cute.get_iter"(%248#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %254 = "cute.get_iter"(%248#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %255 = "cute.get_iter"(%248#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %256 = "cute.get_iter"(%248#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %257 = "cute.get_iter"(%248#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %258 = "cute.get_layout"(%248#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %259 = "cute.get_shape"(%258) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %260:5 = "cute.get_leaves"(%259) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %261 = "cute.get_layout"(%205) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %262 = "cute.get_shape"(%261) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %263:5 = "cute.get_leaves"(%262) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %264 = "cute.get_layout"(%248#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %265 = "cute.make_shape"() : () -> !cute.shape<"1">
      %266 = "cute.make_layout"(%265) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %267 = "cute.append_to_rank"(%264, %266) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %268 = "cute.make_view"(%257, %267) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %269 = "cute.get_iter"(%268) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %270 = "cute.get_layout"(%268) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %271 = "cute.get_shape"(%270) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %272:5 = "cute.get_leaves"(%271) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %273 = "cute.get_layout"(%268) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %274 = "cute.get_shape"(%273) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %275:5 = "cute.get_leaves"(%274) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %276 = "cute.group_modes"(%268) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %277 = "cute.get_iter"(%276) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %278 = "cute.get_iter"(%276) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %279 = "cute.get_layout"(%205) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %280 = "cute.make_shape"() : () -> !cute.shape<"1">
      %281 = "cute.make_layout"(%280) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %282 = "cute.append_to_rank"(%279, %281) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %283 = "cute.make_view"(%206, %282) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %284 = "cute.get_iter"(%283) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %285 = "cute.get_layout"(%283) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %286 = "cute.get_shape"(%285) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %287:5 = "cute.get_leaves"(%286) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %288 = "cute.get_layout"(%283) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %289 = "cute.get_shape"(%288) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %290:5 = "cute.get_leaves"(%289) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %291 = "cute.group_modes"(%283) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %292 = "cute.get_iter"(%291) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %293 = "cute.get_iter"(%291) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %294 = "cute.get_layout"(%242) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %295 = "cute.make_shape"() : () -> !cute.shape<"1">
      %296 = "cute.make_layout"(%295) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %297 = "cute.append_to_rank"(%294, %296) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %298 = "cute.make_view"(%245, %297) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %299 = "cute.get_iter"(%298) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %300 = "cute.get_layout"(%298) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %301 = "cute.get_shape"(%300) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %302:5 = "cute.get_leaves"(%301) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %303 = "cute.get_layout"(%298) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %304 = "cute.get_shape"(%303) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %305:5 = "cute.get_leaves"(%304) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %306 = "cute.group_modes"(%298) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %307 = "cute.get_iter"(%306) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %308 = "cute.get_iter"(%306) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %309 = "cute.get_layout"(%276) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %310 = "cute.get_shape"(%309) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %311:5 = "cute.get_leaves"(%310) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %312 = "cute.get_layout"(%291) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %313 = "cute.get_shape"(%312) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %314:5 = "cute.get_leaves"(%313) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %315 = "cute.size"(%276) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %316 = "cute.get_leaves"(%315) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %317 = "cute.size"(%291) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %318 = "cute.get_leaves"(%317) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%140, %276, %291, %306) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_4, !memref_gmem_f32_4, !memref_gmem_f32_4, !cuda.stream) -> i32, sym_name = "cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False"}> ({
  ^bb0(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4, %arg3: !cuda.stream):
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
    %78 = "arith.extsi"(%77) : (i32) -> i64
    %79 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %80 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %81 = "cuda.launch_cfg.create"(%79, %80, %80, %78, %70, %80, %80, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %82 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%81, %82) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %83 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%81, %83) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %84 = "cuda.launch_ex"(%81, %30, %34, %38, %54, %65, %67) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %85 = "cuda.cast"(%84) : (!cuda.result) -> i32
    "cuda.return_if_error"(%85) : (i32) -> ()
    %86 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%86) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
