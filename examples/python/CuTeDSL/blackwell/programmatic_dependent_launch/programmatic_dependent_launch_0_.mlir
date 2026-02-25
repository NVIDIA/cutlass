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
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}, {}, {}, {}, {}], function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !memref_gmem_f32_, %arg7: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg8: i32, %arg9: i32, %arg10: !cute.layout<"(4,32):(32,1)">, %arg11: !cute.layout<"(4,4):(4,1)">):
      %87 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %88 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %89 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %90 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %91 = "cute.deref_arith_tuple_iter"(%90) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %92:2 = "cute.get_leaves"(%91) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %93 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %94 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %95 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %96 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %97 = "cute.deref_arith_tuple_iter"(%96) : (!cute.arith_tuple_iter<"(0,0)">) -> !cute.int_tuple<"(0,0)">
      %98:2 = "cute.get_leaves"(%97) : (!cute.int_tuple<"(0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %99 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %100 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %101 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %102 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %103 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %104 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %105 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %106 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %107 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %108 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %109 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %110 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %111 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %112 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %113 = "cute.make_coord"(%110) : (i32) -> !cute.coord<"((_,_),?)">
      %114 = "cute.slice"(%arg4, %113) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %115 = "cute.get_iter"(%114) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %116 = "cute.get_iter"(%114) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %117 = "cute.make_coord"(%110) : (i32) -> !cute.coord<"((_,_),?)">
      %118 = "cute.slice"(%arg5, %117) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %119 = "cute.get_iter"(%118) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %120 = "cute.get_iter"(%118) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %121 = "cute.make_coord"(%110) : (i32) -> !cute.coord<"((_,_),?)">
      %122 = "cute.slice"(%arg6, %121) : (!memref_gmem_f32_, !cute.coord<"((_,_),?)">) -> !memref_gmem_f32_1
      %123 = "cute.get_iter"(%122) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %124 = "cute.get_iter"(%122) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %125 = "cute.make_coord"(%110) : (i32) -> !cute.coord<"((_,_),?)">
      %126 = "cute.slice"(%arg7, %125) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">) -> !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %127 = "cute.get_iter"(%126) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %128 = "cute.deref_arith_tuple_iter"(%127) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %129:2 = "cute.get_leaves"(%128) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %130 = "cute.get_scalars"(%129#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %131 = "cute.get_scalars"(%129#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %132 = "cute.get_iter"(%126) : (!cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %133 = "cute.deref_arith_tuple_iter"(%132) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %134:2 = "cute.get_leaves"(%133) : (!cute.int_tuple<"(?{div=16},?{div=128})">) -> (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">)
      %135 = "cute.get_scalars"(%134#0) : (!cute.int_tuple<"?{div=16}">) -> i32
      %136 = "cute.get_scalars"(%134#1) : (!cute.int_tuple<"?{div=128}">) -> i32
      %137 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %138 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %139 = "cute.raked_product"(%arg10, %arg11) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %140 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %141 = "cute.get_leaves"(%140) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %142 = "cute.size"(%arg11) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %143 = "cute.get_leaves"(%142) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %144 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %145 = "cute.make_layout"(%144) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %146 = "cute.right_inverse"(%139) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %147 = "cute.composition"(%146, %145) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %148 = "cute.get_shape"(%139) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %149:4 = "cute.get_leaves"(%148) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %150 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %151 = "cute.tuple.product_each"(%150) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %152:2 = "cute.get_leaves"(%151) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %153 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %154 = "cute.tuple.product_each"(%153) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %155:2 = "cute.get_leaves"(%154) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %156 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %157 = "cute.make_tiled_copy"(%137) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %158 = "cute.raked_product"(%arg10, %arg11) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %159 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %160 = "cute.get_leaves"(%159) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %161 = "cute.size"(%arg11) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %162 = "cute.get_leaves"(%161) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %163 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %164 = "cute.make_layout"(%163) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %165 = "cute.right_inverse"(%158) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %166 = "cute.composition"(%165, %164) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %167 = "cute.get_shape"(%158) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %168:4 = "cute.get_leaves"(%167) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %169 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %170 = "cute.tuple.product_each"(%169) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %171:2 = "cute.get_leaves"(%170) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %172 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %173 = "cute.tuple.product_each"(%172) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %174:2 = "cute.get_leaves"(%173) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %175 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %176 = "cute.make_tiled_copy"(%137) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %177 = "cute.raked_product"(%arg10, %arg11) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %178 = "cute.size"(%arg10) <{mode = array<i32>}> : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %179 = "cute.get_leaves"(%178) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
      %180 = "cute.size"(%arg11) <{mode = array<i32>}> : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %181 = "cute.get_leaves"(%180) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %182 = "cute.make_shape"() : () -> !cute.shape<"(128,16)">
      %183 = "cute.make_layout"(%182) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"(128,16)">) -> !cute.layout<"(128,16):(1,128)">
      %184 = "cute.right_inverse"(%177) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %185 = "cute.composition"(%184, %183) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %186 = "cute.get_shape"(%177) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %187:4 = "cute.get_leaves"(%186) : (!cute.shape<"((4,4),(4,32))">) -> (!cute.shape<"4">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"32">)
      %188 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %189 = "cute.tuple.product_each"(%188) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %190:2 = "cute.get_leaves"(%189) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %191 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,128)">
      %192 = "cute.tuple.product_each"(%191) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %193:2 = "cute.get_leaves"(%192) : (!cute.int_tuple<"(16,128)">) -> (!cute.int_tuple<"16">, !cute.int_tuple<"128">)
      %194 = "cute.make_tile"() : () -> !cute.tile<"[16:1;128:1]">
      %195 = "cute.make_tiled_copy"(%138) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %196 = "cute.make_coord"(%107) : (i32) -> !cute.coord<"?">
      %197 = "cute.tiled.copy.partition_S"(%157, %114, %196) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %198 = "cute.get_iter"(%197) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %199 = "cute.make_coord"(%107) : (i32) -> !cute.coord<"?">
      %200 = "cute.tiled.copy.partition_S"(%176, %118, %199) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %201 = "cute.get_iter"(%200) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %202 = "cute.make_coord"(%107) : (i32) -> !cute.coord<"?">
      %203 = "cute.tiled.copy.partition_S"(%195, %122, %202) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %204 = "cute.get_iter"(%203) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %205 = "cute.get_layout"(%197) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %206 = "cute.make_layout_like"(%205) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %207 = "cute.memref.alloca"(%206) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %208 = "cute.get_iter"(%207) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %209 = "cute.get_iter"(%207) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %210 = "cute.get_layout"(%200) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %211 = "cute.make_layout_like"(%210) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %212 = "cute.memref.alloca"(%211) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %213 = "cute.get_iter"(%212) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %214 = "cute.get_iter"(%212) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %215 = "cute.get_layout"(%203) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %216 = "cute.make_layout_like"(%215) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %217 = "cute.memref.alloca"(%216) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %218 = "cute.get_iter"(%217) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %219 = "cute.get_iter"(%217) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %220 = "cute.make_coord"(%107) : (i32) -> !cute.coord<"?">
      %221 = "cute.tiled.copy.partition_S"(%195, %126, %220) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %222 = "cute.get_iter"(%221) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %223 = "cute.deref_arith_tuple_iter"(%222) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %224:2 = "cute.get_leaves"(%223) : (!cute.int_tuple<"(?{div=4},?{div=4})">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">)
      %225 = "cute.get_scalars"(%224#0) : (!cute.int_tuple<"?{div=4}">) -> i32
      %226 = "cute.get_scalars"(%224#1) : (!cute.int_tuple<"?{div=4}">) -> i32
      %227 = "cute.get_layout"(%221) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %228 = "cute.get_shape"(%227) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %229:5 = "cute.get_leaves"(%228) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %230 = "cute.make_shape"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %231 = "cute.make_layout"(%230) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"((1,(4,4)),1,1)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %232 = "cute.memref.alloca"(%231) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %233 = "cute.get_iter"(%232) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %234 = "cute.get_iter"(%232) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %235 = "cute.size"(%232) <{mode = array<i32>}> : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %236 = "cute.get_leaves"(%235) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %237 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %238 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %239 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %240 = "scf.for"(%237, %238, %239, %232) ({
      ^bb0(%arg19: i32, %arg20: !memref_rmem_i8_):
        %600 = "cute.get_iter"(%arg20) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %601 = "cute.get_iter"(%arg20) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %602 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"?">
        %603 = "cute.slice"(%221, %602) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?)", "():()">
        %604 = "cute.get_iter"(%603) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %605 = "cute.deref_arith_tuple_iter"(%604) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %606:2 = "cute.get_leaves"(%605) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %607 = "cute.get_scalars"(%606#0) : (!cute.int_tuple<"?">) -> i32
        %608 = "cute.get_scalars"(%606#1) : (!cute.int_tuple<"?">) -> i32
        %609 = "cute.get_iter"(%603) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %610 = "cute.deref_arith_tuple_iter"(%609) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %611:2 = "cute.get_leaves"(%610) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %612 = "cute.get_scalars"(%611#0) : (!cute.int_tuple<"?">) -> i32
        %613 = "cute.get_scalars"(%611#1) : (!cute.int_tuple<"?">) -> i32
        %614 = "cute.get_iter"(%603) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %615 = "cute.deref_arith_tuple_iter"(%614) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %616:2 = "cute.get_leaves"(%615) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %617 = "cute.get_scalars"(%616#0) : (!cute.int_tuple<"?">) -> i32
        %618 = "cute.get_scalars"(%616#1) : (!cute.int_tuple<"?">) -> i32
        %619 = "cute.make_coord"(%616#0, %616#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %620 = "cute.make_coord"(%arg8, %arg9) : (i32, i32) -> !cute.coord<"(?,?)">
        %621 = "cute.elem_less"(%619, %620) : (!cute.coord<"(?,?)">, !cute.coord<"(?,?)">) -> i1
        %622 = "arith.extui"(%621) : (i1) -> i8
        %623 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg20, %623, %622) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg20) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %241 = "cute.get_iter"(%240) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %242 = "cute.get_iter"(%240) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %243 = "cute.get_iter"(%240) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %244 = "arith.constant"() <{value = false}> : () -> i1
      "scf.if"(%244) ({
        %475 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %476 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %477 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%475, %476, %477) ({
        ^bb0(%arg18: i32):
          %478 = "cute.get_layout"(%197) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %479 = "cute.get_shape"(%478) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %480:5 = "cute.get_leaves"(%479) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %481 = "cute.get_layout"(%207) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %482 = "cute.get_shape"(%481) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %483:5 = "cute.get_leaves"(%482) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %484 = "cute.get_layout"(%197) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %485 = "cute.make_shape"() : () -> !cute.shape<"1">
          %486 = "cute.make_layout"(%485) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %487 = "cute.append_to_rank"(%484, %486) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %488 = "cute.make_view"(%198, %487) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %489 = "cute.get_iter"(%488) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %490 = "cute.get_layout"(%488) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %491 = "cute.get_shape"(%490) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %492:5 = "cute.get_leaves"(%491) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %493 = "cute.get_layout"(%488) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %494 = "cute.get_shape"(%493) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %495:5 = "cute.get_leaves"(%494) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %496 = "cute.group_modes"(%488) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %497 = "cute.get_iter"(%496) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %498 = "cute.get_iter"(%496) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %499 = "cute.get_layout"(%207) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %500 = "cute.make_shape"() : () -> !cute.shape<"1">
          %501 = "cute.make_layout"(%500) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %502 = "cute.append_to_rank"(%499, %501) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %503 = "cute.make_view"(%209, %502) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %504 = "cute.get_iter"(%503) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %505 = "cute.get_layout"(%503) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %506 = "cute.get_shape"(%505) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %507:5 = "cute.get_leaves"(%506) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %508 = "cute.get_layout"(%503) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %509 = "cute.get_shape"(%508) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %510:5 = "cute.get_leaves"(%509) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %511 = "cute.group_modes"(%503) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %512 = "cute.get_iter"(%511) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %513 = "cute.get_iter"(%511) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %514 = "cute.get_layout"(%240) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %515 = "cute.make_shape"() : () -> !cute.shape<"1">
          %516 = "cute.make_layout"(%515) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %517 = "cute.append_to_rank"(%514, %516) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %518 = "cute.make_view"(%243, %517) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %519 = "cute.get_iter"(%518) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %520 = "cute.get_layout"(%518) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %521 = "cute.get_shape"(%520) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %522:5 = "cute.get_leaves"(%521) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %523 = "cute.get_layout"(%518) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %524 = "cute.get_shape"(%523) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %525:5 = "cute.get_leaves"(%524) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %526 = "cute.group_modes"(%518) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %527 = "cute.get_iter"(%526) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %528 = "cute.get_iter"(%526) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %529 = "cute.get_layout"(%496) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %530 = "cute.get_shape"(%529) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %531:5 = "cute.get_leaves"(%530) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %532 = "cute.get_layout"(%511) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %533 = "cute.get_shape"(%532) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %534:5 = "cute.get_leaves"(%533) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %535 = "cute.size"(%496) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %536 = "cute.get_leaves"(%535) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %537 = "cute.size"(%511) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %538 = "cute.get_leaves"(%537) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%137, %496, %511, %526) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          %539 = "cute.get_layout"(%200) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %540 = "cute.get_shape"(%539) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %541:5 = "cute.get_leaves"(%540) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %542 = "cute.get_layout"(%212) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %543 = "cute.get_shape"(%542) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %544:5 = "cute.get_leaves"(%543) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %545 = "cute.get_layout"(%200) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %546 = "cute.make_shape"() : () -> !cute.shape<"1">
          %547 = "cute.make_layout"(%546) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %548 = "cute.append_to_rank"(%545, %547) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %549 = "cute.make_view"(%201, %548) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %550 = "cute.get_iter"(%549) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %551 = "cute.get_layout"(%549) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %552 = "cute.get_shape"(%551) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %553:5 = "cute.get_leaves"(%552) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %554 = "cute.get_layout"(%549) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %555 = "cute.get_shape"(%554) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %556:5 = "cute.get_leaves"(%555) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %557 = "cute.group_modes"(%549) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %558 = "cute.get_iter"(%557) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %559 = "cute.get_iter"(%557) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %560 = "cute.get_layout"(%212) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %561 = "cute.make_shape"() : () -> !cute.shape<"1">
          %562 = "cute.make_layout"(%561) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %563 = "cute.append_to_rank"(%560, %562) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %564 = "cute.make_view"(%214, %563) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %565 = "cute.get_iter"(%564) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %566 = "cute.get_layout"(%564) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %567 = "cute.get_shape"(%566) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %568:5 = "cute.get_leaves"(%567) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %569 = "cute.get_layout"(%564) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %570 = "cute.get_shape"(%569) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %571:5 = "cute.get_leaves"(%570) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %572 = "cute.group_modes"(%564) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %573 = "cute.get_iter"(%572) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %574 = "cute.get_iter"(%572) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %575 = "cute.get_layout"(%240) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %576 = "cute.make_shape"() : () -> !cute.shape<"1">
          %577 = "cute.make_layout"(%576) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %578 = "cute.append_to_rank"(%575, %577) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %579 = "cute.make_view"(%243, %578) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %580 = "cute.get_iter"(%579) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %581 = "cute.get_layout"(%579) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %582 = "cute.get_shape"(%581) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %583:5 = "cute.get_leaves"(%582) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %584 = "cute.get_layout"(%579) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %585 = "cute.get_shape"(%584) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %586:5 = "cute.get_leaves"(%585) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %587 = "cute.group_modes"(%579) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %588 = "cute.get_iter"(%587) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %589 = "cute.get_iter"(%587) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %590 = "cute.get_layout"(%557) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %591 = "cute.get_shape"(%590) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %592:5 = "cute.get_leaves"(%591) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %593 = "cute.get_layout"(%572) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %594 = "cute.get_shape"(%593) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %595:5 = "cute.get_leaves"(%594) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %596 = "cute.size"(%557) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %597 = "cute.get_leaves"(%596) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %598 = "cute.size"(%572) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %599 = "cute.get_leaves"(%598) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%137, %557, %572, %587) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.launch_dependents;", constraints = "", has_side_effects}> : () -> ()
        "scf.yield"() : () -> ()
      }, {
        %350 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %351 = "arith.constant"() <{value = 10 : i32}> : () -> i32
        %352 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%350, %351, %352) ({
        ^bb0(%arg17: i32):
          %414 = "cute.get_layout"(%200) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %415 = "cute.get_shape"(%414) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %416:5 = "cute.get_leaves"(%415) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %417 = "cute.get_layout"(%212) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %418 = "cute.get_shape"(%417) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %419:5 = "cute.get_leaves"(%418) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %420 = "cute.get_layout"(%200) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %421 = "cute.make_shape"() : () -> !cute.shape<"1">
          %422 = "cute.make_layout"(%421) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %423 = "cute.append_to_rank"(%420, %422) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %424 = "cute.make_view"(%201, %423) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %425 = "cute.get_iter"(%424) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %426 = "cute.get_layout"(%424) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %427 = "cute.get_shape"(%426) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %428:5 = "cute.get_leaves"(%427) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %429 = "cute.get_layout"(%424) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %430 = "cute.get_shape"(%429) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %431:5 = "cute.get_leaves"(%430) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %432 = "cute.group_modes"(%424) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %433 = "cute.get_iter"(%432) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %434 = "cute.get_iter"(%432) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %435 = "cute.get_layout"(%212) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %436 = "cute.make_shape"() : () -> !cute.shape<"1">
          %437 = "cute.make_layout"(%436) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %438 = "cute.append_to_rank"(%435, %437) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %439 = "cute.make_view"(%214, %438) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %440 = "cute.get_iter"(%439) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %441 = "cute.get_layout"(%439) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %442 = "cute.get_shape"(%441) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %443:5 = "cute.get_leaves"(%442) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %444 = "cute.get_layout"(%439) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %445 = "cute.get_shape"(%444) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %446:5 = "cute.get_leaves"(%445) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %447 = "cute.group_modes"(%439) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %448 = "cute.get_iter"(%447) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %449 = "cute.get_iter"(%447) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %450 = "cute.get_layout"(%240) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %451 = "cute.make_shape"() : () -> !cute.shape<"1">
          %452 = "cute.make_layout"(%451) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %453 = "cute.append_to_rank"(%450, %452) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %454 = "cute.make_view"(%243, %453) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %455 = "cute.get_iter"(%454) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %456 = "cute.get_layout"(%454) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %457 = "cute.get_shape"(%456) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %458:5 = "cute.get_leaves"(%457) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %459 = "cute.get_layout"(%454) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %460 = "cute.get_shape"(%459) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %461:5 = "cute.get_leaves"(%460) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %462 = "cute.group_modes"(%454) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %463 = "cute.get_iter"(%462) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %464 = "cute.get_iter"(%462) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %465 = "cute.get_layout"(%432) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %466 = "cute.get_shape"(%465) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %467:5 = "cute.get_leaves"(%466) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %468 = "cute.get_layout"(%447) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %469 = "cute.get_shape"(%468) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %470:5 = "cute.get_leaves"(%469) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %471 = "cute.size"(%432) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %472 = "cute.get_leaves"(%471) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %473 = "cute.size"(%447) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %474 = "cute.get_leaves"(%473) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%137, %432, %447, %462) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.wait;", constraints = "", has_side_effects}> : () -> ()
        "scf.for"(%350, %351, %352) ({
        ^bb0(%arg16: i32):
          %353 = "cute.get_layout"(%197) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %354 = "cute.get_shape"(%353) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %355:5 = "cute.get_leaves"(%354) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %356 = "cute.get_layout"(%207) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %357 = "cute.get_shape"(%356) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %358:5 = "cute.get_leaves"(%357) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %359 = "cute.get_layout"(%197) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %360 = "cute.make_shape"() : () -> !cute.shape<"1">
          %361 = "cute.make_layout"(%360) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %362 = "cute.append_to_rank"(%359, %361) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %363 = "cute.make_view"(%198, %362) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
          %364 = "cute.get_iter"(%363) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
          %365 = "cute.get_layout"(%363) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %366 = "cute.get_shape"(%365) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %367:5 = "cute.get_leaves"(%366) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %368 = "cute.get_layout"(%363) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %369 = "cute.get_shape"(%368) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %370:5 = "cute.get_leaves"(%369) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %371 = "cute.group_modes"(%363) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %372 = "cute.get_iter"(%371) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %373 = "cute.get_iter"(%371) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %374 = "cute.get_layout"(%207) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %375 = "cute.make_shape"() : () -> !cute.shape<"1">
          %376 = "cute.make_layout"(%375) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %377 = "cute.append_to_rank"(%374, %376) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %378 = "cute.make_view"(%209, %377) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
          %379 = "cute.get_iter"(%378) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
          %380 = "cute.get_layout"(%378) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %381 = "cute.get_shape"(%380) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %382:5 = "cute.get_leaves"(%381) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %383 = "cute.get_layout"(%378) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %384 = "cute.get_shape"(%383) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %385:5 = "cute.get_leaves"(%384) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %386 = "cute.group_modes"(%378) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %387 = "cute.get_iter"(%386) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %388 = "cute.get_iter"(%386) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
          %389 = "cute.get_layout"(%240) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %390 = "cute.make_shape"() : () -> !cute.shape<"1">
          %391 = "cute.make_layout"(%390) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
          %392 = "cute.append_to_rank"(%389, %391) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %393 = "cute.make_view"(%243, %392) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
          %394 = "cute.get_iter"(%393) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %395 = "cute.get_layout"(%393) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %396 = "cute.get_shape"(%395) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %397:5 = "cute.get_leaves"(%396) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %398 = "cute.get_layout"(%393) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %399 = "cute.get_shape"(%398) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %400:5 = "cute.get_leaves"(%399) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %401 = "cute.group_modes"(%393) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %402 = "cute.get_iter"(%401) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %403 = "cute.get_iter"(%401) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %404 = "cute.get_layout"(%371) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %405 = "cute.get_shape"(%404) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %406:5 = "cute.get_leaves"(%405) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %407 = "cute.get_layout"(%386) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
          %408 = "cute.get_shape"(%407) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %409:5 = "cute.get_leaves"(%408) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
          %410 = "cute.size"(%371) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %411 = "cute.get_leaves"(%410) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %412 = "cute.size"(%386) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %413 = "cute.get_leaves"(%412) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          "cute.copy"(%137, %371, %386, %401) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1) -> ()
          "scf.yield"() : () -> ()
        }) : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %245 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %246:3 = "scf.for"(%237, %245, %239, %207, %212, %217) ({
      ^bb0(%arg12: i32, %arg13: !memref_rmem_f32_, %arg14: !memref_rmem_f32_, %arg15: !memref_rmem_f32_):
        %317 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %318 = "cute.get_iter"(%arg14) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %319 = "cute.get_iter"(%arg15) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %320 = "cute.get_iter"(%arg13) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %321 = "cute.get_iter"(%arg14) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %322 = "cute.get_iter"(%arg15) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %323 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %324 = "cute.get_shape"(%323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %325:5 = "cute.get_leaves"(%324) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %326 = "cute.memref.load_vec"(%arg13) : (!memref_rmem_f32_) -> vector<16xf32>
        %327 = "cute.get_layout"(%arg13) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %328 = "cute.get_shape"(%327) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %329:5 = "cute.get_leaves"(%328) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %330 = "cute.get_layout"(%arg14) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %331 = "cute.get_shape"(%330) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %332:5 = "cute.get_leaves"(%331) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %333 = "cute.memref.load_vec"(%arg14) : (!memref_rmem_f32_) -> vector<16xf32>
        %334 = "cute.get_layout"(%arg14) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %335 = "cute.get_shape"(%334) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %336:5 = "cute.get_leaves"(%335) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %337 = "arith.addf"(%326, %333) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
        %338 = "cute.get_layout"(%arg15) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %339 = "cute.get_shape"(%338) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %340:5 = "cute.get_leaves"(%339) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %341 = "cute.get_layout"(%arg15) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
        %342 = "cute.get_shape"(%341) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %343:5 = "cute.get_leaves"(%342) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
        %344 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %345 = "cute.size"(%344) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %346 = "cute.get_leaves"(%345) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        %347 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %348 = "cute.size"(%347) <{mode = array<i32>}> : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %349 = "cute.get_leaves"(%348) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
        "cute.memref.store_vec"(%337, %arg15) : (vector<16xf32>, !memref_rmem_f32_) -> ()
        "scf.yield"(%arg13, %arg14, %arg15) : (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> ()
      }) : (i32, i32, i32, !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)
      %247 = "cute.get_iter"(%246#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %248 = "cute.get_iter"(%246#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %249 = "cute.get_iter"(%246#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %250 = "cute.get_iter"(%246#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %251 = "cute.get_iter"(%246#0) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %252 = "cute.get_iter"(%246#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %253 = "cute.get_iter"(%246#1) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %254 = "cute.get_iter"(%246#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %255 = "cute.get_iter"(%246#2) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %256 = "cute.get_layout"(%246#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %257 = "cute.get_shape"(%256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %258:5 = "cute.get_leaves"(%257) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %259 = "cute.get_layout"(%203) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %260 = "cute.get_shape"(%259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %261:5 = "cute.get_leaves"(%260) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %262 = "cute.get_layout"(%246#2) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %263 = "cute.make_shape"() : () -> !cute.shape<"1">
      %264 = "cute.make_layout"(%263) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %265 = "cute.append_to_rank"(%262, %264) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %266 = "cute.make_view"(%255, %265) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_f32_
      %267 = "cute.get_iter"(%266) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %268 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %269 = "cute.get_shape"(%268) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %270:5 = "cute.get_leaves"(%269) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %271 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %272 = "cute.get_shape"(%271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %273:5 = "cute.get_leaves"(%272) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %274 = "cute.group_modes"(%266) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %275 = "cute.get_iter"(%274) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %276 = "cute.get_iter"(%274) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
      %277 = "cute.get_layout"(%203) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %278 = "cute.make_shape"() : () -> !cute.shape<"1">
      %279 = "cute.make_layout"(%278) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %280 = "cute.append_to_rank"(%277, %279) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %281 = "cute.make_view"(%204, %280) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !memref_gmem_f32_2
      %282 = "cute.get_iter"(%281) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %283 = "cute.get_layout"(%281) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %284 = "cute.get_shape"(%283) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %285:5 = "cute.get_leaves"(%284) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %286 = "cute.get_layout"(%281) : (!memref_gmem_f32_2) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %287 = "cute.get_shape"(%286) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %288:5 = "cute.get_leaves"(%287) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %289 = "cute.group_modes"(%281) <{begin = 1 : i32, end = 3 : i32}> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %290 = "cute.get_iter"(%289) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %291 = "cute.get_iter"(%289) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %292 = "cute.get_layout"(%240) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %293 = "cute.make_shape"() : () -> !cute.shape<"1">
      %294 = "cute.make_layout"(%293) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
      %295 = "cute.append_to_rank"(%292, %294) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %296 = "cute.make_view"(%243, %295) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !memref_rmem_i8_
      %297 = "cute.get_iter"(%296) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %298 = "cute.get_layout"(%296) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %299 = "cute.get_shape"(%298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %300:5 = "cute.get_leaves"(%299) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %301 = "cute.get_layout"(%296) : (!memref_rmem_i8_) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %302 = "cute.get_shape"(%301) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %303:5 = "cute.get_leaves"(%302) : (!cute.shape<"((1,(4,4)),1,1)">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %304 = "cute.group_modes"(%296) <{begin = 1 : i32, end = 3 : i32}> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %305 = "cute.get_iter"(%304) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %306 = "cute.get_iter"(%304) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %307 = "cute.get_layout"(%274) : (!memref_rmem_f32_1) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
      %308 = "cute.get_shape"(%307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %309:5 = "cute.get_leaves"(%308) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %310 = "cute.get_layout"(%289) : (!memref_gmem_f32_3) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %311 = "cute.get_shape"(%310) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %312:5 = "cute.get_leaves"(%311) : (!cute.shape<"((1,(4,4)),(1,1))">) -> (!cute.shape<"1">, !cute.shape<"4">, !cute.shape<"4">, !cute.shape<"1">, !cute.shape<"1">)
      %313 = "cute.size"(%274) <{mode = array<i32: 1>}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %314 = "cute.get_leaves"(%313) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %315 = "cute.size"(%289) <{mode = array<i32: 1>}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %316 = "cute.get_leaves"(%315) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      "cute.copy"(%138, %274, %289, %304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1) -> ()
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
    %84 = "cuda.launch_ex"(%81, %30, %34, %38, %54, %65, %67, %11, %14) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cuda.result
    %85 = "cuda.cast"(%84) : (!cuda.result) -> i32
    "cuda.return_if_error"(%85) : (i32) -> ()
    %86 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%86) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
