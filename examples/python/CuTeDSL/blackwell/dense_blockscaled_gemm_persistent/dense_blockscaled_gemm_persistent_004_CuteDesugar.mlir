!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f4E2M1FN = !cute.memref<f4E2M1FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(8,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(8,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_i8_, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %121 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %122 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %123 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %124 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %125 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %126 = "cute.deref_arith_tuple_iter"(%125) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %127:3 = "cute.get_leaves"(%126) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %128 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %129 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %130 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %131 = "cute.deref_arith_tuple_iter"(%130) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %132:3 = "cute.get_leaves"(%131) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %133 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %134 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %135 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %136 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %137 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %138 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %139 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %140 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %141 = "cute.make_coord"(%140) : (i32) -> !cute.coord<"(_,?)">
      %142 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %143 = "cute.crd2idx"(%141, %142) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %144 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %145 = "cute.add_offset"(%144, %143) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %146 = "cute.make_view"(%145) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_1
      %147 = "cute.get_iter"(%146) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %148 = "cute.get_iter"(%146) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %149 = "cute.make_coord"(%140) : (i32) -> !cute.coord<"(_,?)">
      %150 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %151 = "cute.crd2idx"(%149, %150) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %152 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %153 = "cute.add_offset"(%152, %151) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %154 = "cute.make_view"(%153) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_1
      %155 = "cute.get_iter"(%154) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %156 = "cute.get_iter"(%154) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %157 = "cute.make_coord"(%140) : (i32) -> !cute.coord<"(_,?)">
      %158 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %159 = "cute.crd2idx"(%157, %158) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %160 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %161 = "cute.add_offset"(%160, %159) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %162 = "cute.make_view"(%161) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %163 = "cute.get_iter"(%162) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %164 = "cute.deref_arith_tuple_iter"(%163) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %165:3 = "cute.get_leaves"(%164) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %166 = "cute.get_scalars"(%165#0) : (!cute.int_tuple<"?">) -> i32
      %167 = "cute.get_scalars"(%165#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %168 = "cute.get_scalars"(%165#2) : (!cute.int_tuple<"?">) -> i32
      %169 = "cute.get_iter"(%162) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %170 = "cute.deref_arith_tuple_iter"(%169) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %171:3 = "cute.get_leaves"(%170) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %172 = "cute.get_scalars"(%171#0) : (!cute.int_tuple<"?">) -> i32
      %173 = "cute.get_scalars"(%171#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %174 = "cute.get_scalars"(%171#2) : (!cute.int_tuple<"?">) -> i32
      %175 = "cute.get_iter"(%146) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %176 = "cute.make_view"(%175) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_2
      %177 = "cute.get_iter"(%176) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %178 = "cute.get_iter"(%154) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %179 = "cute.make_view"(%178) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_2
      %180 = "cute.get_iter"(%179) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %181 = "cute.get_iter"(%162) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %182 = "cute.make_view"(%181) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %183 = "cute.get_iter"(%182) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %184 = "cute.deref_arith_tuple_iter"(%183) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %185:3 = "cute.get_leaves"(%184) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %186 = "cute.get_scalars"(%185#0) : (!cute.int_tuple<"?">) -> i32
      %187 = "cute.get_scalars"(%185#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %188 = "cute.get_scalars"(%185#2) : (!cute.int_tuple<"?">) -> i32
      %189 = "cute.make_coord"(%139) : (i32) -> !cute.coord<"(?,_)">
      %190 = "cute.get_layout"(%176) : (!memref_gmem_f32_2) -> !cute.layout<"(128,8):(8,1)">
      %191 = "cute.crd2idx"(%189, %190) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %192 = "cute.get_iter"(%176) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %193 = "cute.add_offset"(%192, %191) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %194 = "cute.make_view"(%193) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_3
      %195 = "cute.get_iter"(%194) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %196 = "cute.get_iter"(%194) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %197 = "cute.make_coord"(%139) : (i32) -> !cute.coord<"(?,_)">
      %198 = "cute.get_layout"(%179) : (!memref_gmem_i8_2) -> !cute.layout<"(128,4):(4,1)">
      %199 = "cute.crd2idx"(%197, %198) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %200 = "cute.get_iter"(%179) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %201 = "cute.add_offset"(%200, %199) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %202 = "cute.make_view"(%201) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_3
      %203 = "cute.get_iter"(%202) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %204 = "cute.get_iter"(%202) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %205 = "cute.make_coord"(%139) : (i32) -> !cute.coord<"(?,_)">
      %206 = "cute.get_layout"(%182) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.layout<"(128,8):(8@1,1@1)">
      %207 = "cute.crd2idx"(%205, %206) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %208 = "cute.get_iter"(%182) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %209 = "cute.add_offset"(%208, %207) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %210 = "cute.make_view"(%209) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %211 = "cute.get_iter"(%210) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %212 = "cute.deref_arith_tuple_iter"(%211) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %213:3 = "cute.get_leaves"(%212) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %214 = "cute.get_scalars"(%213#0) : (!cute.int_tuple<"?">) -> i32
      %215 = "cute.get_scalars"(%213#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %216 = "cute.get_scalars"(%213#2) : (!cute.int_tuple<"?">) -> i32
      %217 = "cute.get_iter"(%210) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %218 = "cute.deref_arith_tuple_iter"(%217) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %219:3 = "cute.get_leaves"(%218) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %220 = "cute.get_scalars"(%219#0) : (!cute.int_tuple<"?">) -> i32
      %221 = "cute.get_scalars"(%219#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %222 = "cute.get_scalars"(%219#2) : (!cute.int_tuple<"?">) -> i32
      %223 = "cute.make_coord"() : () -> !cute.coord<"0">
      %224 = "cute.get_layout"(%210) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.layout<"(8):(1@1)">
      %225 = "cute.crd2idx"(%223, %224) : (!cute.coord<"0">, !cute.layout<"(8):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %226 = "cute.get_iter"(%210) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %227 = "cute.add_offset"(%226, %225) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %228 = "cute.make_view"(%227) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %229 = "cute.get_iter"(%228) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %230 = "cute.deref_arith_tuple_iter"(%229) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %231:3 = "cute.get_leaves"(%230) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %232 = "cute.get_scalars"(%231#0) : (!cute.int_tuple<"?">) -> i32
      %233 = "cute.get_scalars"(%231#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %234 = "cute.get_scalars"(%231#2) : (!cute.int_tuple<"?">) -> i32
      %235 = "cute.get_iter"(%228) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %236 = "cute.deref_arith_tuple_iter"(%235) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %237:3 = "cute.get_leaves"(%236) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %238 = "cute.get_scalars"(%237#0) : (!cute.int_tuple<"?">) -> i32
      %239 = "cute.get_scalars"(%237#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %240 = "cute.get_scalars"(%237#2) : (!cute.int_tuple<"?">) -> i32
      %241 = "cute.get_iter"(%228) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %242 = "cute.deref_arith_tuple_iter"(%241) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %243:3 = "cute.get_leaves"(%242) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %244 = "cute.get_scalars"(%243#0) : (!cute.int_tuple<"?">) -> i32
      %245 = "cute.get_scalars"(%243#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %246 = "cute.get_scalars"(%243#2) : (!cute.int_tuple<"?">) -> i32
      %247 = "cute.make_coord"(%243#0, %243#1, %243#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %248 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %249 = "cute.elem_less"(%247, %248) : (!cute.coord<"(?,?{div=8},?)">, !cute.coord<"(?,?,?)">) -> i1
      "scf.if"(%249) ({
        %250 = "cute.get_shape"(%121) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %251:2 = "cute.get_leaves"(%250) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %252 = "cute.get_shape"(%121) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %253:2 = "cute.get_leaves"(%252) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %254 = "cute.get"(%121) <{mode = array<i32: 1>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"8:1">
        %255 = "cute.memref.alloca"(%254) : (!cute.layout<"8:1">) -> !memref_rmem_f32_
        %256 = "cute.get_iter"(%255) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %257 = "cute.get_iter"(%255) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %258 = "cute.get_shape"(%122) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %259:2 = "cute.get_leaves"(%258) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %260 = "cute.get_shape"(%122) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %261:2 = "cute.get_leaves"(%260) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %262 = "cute.get"(%122) <{mode = array<i32: 1>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.layout<"4:1">
        %263 = "cute.memref.alloca"(%262) : (!cute.layout<"4:1">) -> !memref_rmem_i8_
        %264 = "cute.get_iter"(%263) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %265 = "cute.get_iter"(%263) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %266 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %267 = "cute.get_layout"(%194) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %268 = "cute.get_shape"(%267) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %269 = "cute.get_leaves"(%268) : (!cute.shape<"(8)">) -> !cute.shape<"8">
        %270 = "cute.get_layout"(%255) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %271 = "cute.get_shape"(%270) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %272 = "cute.get_leaves"(%271) : (!cute.shape<"8">) -> !cute.shape<"8">
        %273 = "cute.get_layout"(%194) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %274 = "cute.make_shape"() : () -> !cute.shape<"1">
        %275 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %276 = "cute.append_to_rank"(%273, %275) <{rank = 2 : si32}> : (!cute.layout<"(8):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %277 = "cute.make_view"(%196, %276) : (!cute.ptr<f32, gmem>, !cute.layout<"(8,1):(1,0)">) -> !memref_gmem_f32_4
        %278 = "cute.get_iter"(%277) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %279 = "cute.get_layout"(%277) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %280 = "cute.get_shape"(%279) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %281:2 = "cute.get_leaves"(%280) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %282 = "cute.get_layout"(%277) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %283 = "cute.get_shape"(%282) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %284:2 = "cute.get_leaves"(%283) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %285 = "cute.get_iter"(%277) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %286 = "cute.make_view"(%285) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_5
        %287 = "cute.get_iter"(%286) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %288 = "cute.get_iter"(%286) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %289 = "cute.get_layout"(%255) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %290 = "cute.make_shape"() : () -> !cute.shape<"1">
        %291 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %292 = "cute.append_to_rank"(%289, %291) <{rank = 2 : si32}> : (!cute.layout<"8:1">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %293 = "cute.make_view"(%257, %292) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8,1):(1,0)">) -> !memref_rmem_f32_1
        %294 = "cute.get_iter"(%293) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %295 = "cute.get_layout"(%293) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %296 = "cute.get_shape"(%295) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %297:2 = "cute.get_leaves"(%296) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %298 = "cute.get_layout"(%293) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %299 = "cute.get_shape"(%298) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %300:2 = "cute.get_leaves"(%299) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %301 = "cute.get_iter"(%293) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %302 = "cute.make_view"(%301) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %303 = "cute.get_iter"(%302) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %304 = "cute.get_iter"(%302) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %305 = "cute.get_layout"(%286) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %306 = "cute.get_shape"(%305) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %307:2 = "cute.get_leaves"(%306) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %308 = "cute.get_layout"(%302) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %309 = "cute.get_shape"(%308) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %310:2 = "cute.get_leaves"(%309) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %311 = "cute.get_layout"(%286) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %312 = "cute.size"(%311) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %313 = "cute.get_leaves"(%312) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %314 = "cute.get_layout"(%302) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %315 = "cute.size"(%314) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %316 = "cute.get_leaves"(%315) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %317 = "cute.static"() : () -> !cute.layout<"1:0">
        %318 = "cute.get_iter"(%286) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %319 = "cute.get_iter"(%302) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %320 = "cute.get_layout"(%286) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %321 = "cute.get_layout"(%302) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %322 = "cute.append_to_rank"(%320, %317) <{rank = 2 : si32}> : (!cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1)):(1,(0))">
        %323 = "cute.append_to_rank"(%321, %317) <{rank = 2 : si32}> : (!cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1)):(1,(0))">
        %324 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1))):(1,((0)))">
        %325 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1))):(1,((0)))">
        %326 = "cute.size"(%324) <{mode = array<i32: 1>}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %327 = "cute.get_scalars"(%326) : (!cute.int_tuple<"1">) -> i32
        %328 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %329 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%328, %327, %329) ({
        ^bb0(%arg9: i32):
          %430 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %431 = "cute.slice"(%324, %430) : (!cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
          %432 = "cute.crd2idx"(%430, %324) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %433 = "cute.add_offset"(%318, %432) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %434 = "cute.make_view"(%433, %431) : (!cute.ptr<f32, gmem>, !cute.layout<"(8):(1)">) -> !memref_gmem_f32_3
          %435 = "cute.slice"(%325, %430) : (!cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(8):(1)">
          %436 = "cute.crd2idx"(%430, %325) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %437 = "cute.add_offset"(%319, %436) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %438 = "cute.make_view"(%437, %435) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_f32_3
          "cute.copy_atom_call"(%266, %434, %438) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %330 = "cute.get_layout"(%255) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %331 = "cute.get_shape"(%330) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %332 = "cute.get_leaves"(%331) : (!cute.shape<"8">) -> !cute.shape<"8">
        %333 = "cute.memref.load_vec"(%255) : (!memref_rmem_f32_) -> vector<8xf32>
        %334 = "cute.get_layout"(%255) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %335 = "cute.get_shape"(%334) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %336 = "cute.get_leaves"(%335) : (!cute.shape<"8">) -> !cute.shape<"8">
        %337 = "nvgpu.cvt_fptrunc"(%333) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<8xf32>) -> vector<8xf4E2M1FN>
        %338 = "cute.make_shape"() : () -> !cute.shape<"8">
        %339 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
        %340 = "cute.recast_layout"(%339) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %341 = "cute.get_shape"(%340) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %342 = "cute.get_leaves"(%341) : (!cute.shape<"4">) -> !cute.shape<"4">
        %343 = "builtin.unrealized_conversion_cast"(%337) : (vector<8xf4E2M1FN>) -> vector<8xi4>
        %344 = "vector.bitcast"(%343) : (vector<8xi4>) -> vector<4xi8>
        %345 = "cute.get_layout"(%263) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %346 = "cute.get_shape"(%345) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %347 = "cute.get_leaves"(%346) : (!cute.shape<"4">) -> !cute.shape<"4">
        %348 = "cute.get_layout"(%263) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %349 = "cute.get_shape"(%348) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %350 = "cute.get_leaves"(%349) : (!cute.shape<"4">) -> !cute.shape<"4">
        %351 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %352 = "cute.size"(%351) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %353 = "cute.get_leaves"(%352) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %354 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %355 = "cute.size"(%354) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %356 = "cute.get_leaves"(%355) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        "cute.memref.store_vec"(%344, %263) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %357 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %358 = "cute.get_layout"(%263) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %359 = "cute.get_shape"(%358) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %360 = "cute.get_leaves"(%359) : (!cute.shape<"4">) -> !cute.shape<"4">
        %361 = "cute.get_layout"(%202) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %362 = "cute.get_shape"(%361) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %363 = "cute.get_leaves"(%362) : (!cute.shape<"(4)">) -> !cute.shape<"4">
        %364 = "cute.get_layout"(%263) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %365 = "cute.make_shape"() : () -> !cute.shape<"1">
        %366 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %367 = "cute.append_to_rank"(%364, %366) <{rank = 2 : si32}> : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %368 = "cute.make_view"(%265, %367) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_i8_1
        %369 = "cute.get_iter"(%368) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %370 = "cute.get_layout"(%368) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %371 = "cute.get_shape"(%370) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %372:2 = "cute.get_leaves"(%371) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %373 = "cute.get_layout"(%368) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %374 = "cute.get_shape"(%373) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %375:2 = "cute.get_leaves"(%374) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %376 = "cute.get_iter"(%368) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %377 = "cute.make_view"(%376) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %378 = "cute.get_iter"(%377) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %379 = "cute.get_iter"(%377) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %380 = "cute.get_layout"(%202) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %381 = "cute.make_shape"() : () -> !cute.shape<"1">
        %382 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %383 = "cute.append_to_rank"(%380, %382) <{rank = 2 : si32}> : (!cute.layout<"(4):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %384 = "cute.make_view"(%204, %383) : (!cute.ptr<i8, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_i8_4
        %385 = "cute.get_iter"(%384) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %386 = "cute.get_layout"(%384) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %387 = "cute.get_shape"(%386) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %388:2 = "cute.get_leaves"(%387) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %389 = "cute.get_layout"(%384) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %390 = "cute.get_shape"(%389) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %391:2 = "cute.get_leaves"(%390) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %392 = "cute.get_iter"(%384) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %393 = "cute.make_view"(%392) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_5
        %394 = "cute.get_iter"(%393) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %395 = "cute.get_iter"(%393) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %396 = "cute.get_layout"(%377) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %397 = "cute.get_shape"(%396) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %398:2 = "cute.get_leaves"(%397) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %399 = "cute.get_layout"(%393) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %400 = "cute.get_shape"(%399) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %401:2 = "cute.get_leaves"(%400) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %402 = "cute.get_layout"(%377) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %403 = "cute.size"(%402) <{mode = array<i32: 1>}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %404 = "cute.get_leaves"(%403) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %405 = "cute.get_layout"(%393) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %406 = "cute.size"(%405) <{mode = array<i32: 1>}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %407 = "cute.get_leaves"(%406) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %408 = "cute.static"() : () -> !cute.layout<"1:0">
        %409 = "cute.get_iter"(%377) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %410 = "cute.get_iter"(%393) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %411 = "cute.get_layout"(%377) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %412 = "cute.get_layout"(%393) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %413 = "cute.append_to_rank"(%411, %408) <{rank = 2 : si32}> : (!cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(4,(1)):(1,(0))">
        %414 = "cute.append_to_rank"(%412, %408) <{rank = 2 : si32}> : (!cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(4,(1)):(1,(0))">
        %415 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,((1))):(1,((0)))">
        %416 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,((1))):(1,((0)))">
        %417 = "cute.size"(%415) <{mode = array<i32: 1>}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %418 = "cute.get_scalars"(%417) : (!cute.int_tuple<"1">) -> i32
        %419 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %420 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%419, %418, %420) ({
        ^bb0(%arg8: i32):
          %421 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"(_,?)">
          %422 = "cute.slice"(%415, %421) : (!cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(4):(1)">
          %423 = "cute.crd2idx"(%421, %415) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %424 = "cute.add_offset"(%409, %423) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %425 = "cute.make_view"(%424, %422) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_i8_3
          %426 = "cute.slice"(%416, %421) : (!cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">) -> !cute.layout<"(4):(1)">
          %427 = "cute.crd2idx"(%421, %416) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %428 = "cute.add_offset"(%410, %427) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %429 = "cute.make_view"(%428, %426) : (!cute.ptr<i8, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_i8_3
          "cute.copy_atom_call"(%357, %425, %429) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_3, !memref_gmem_i8_3) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_f4E2M1FN) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_8"}> ({
  ^bb0(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.ptr<f4E2M1FN, gmem, align<16>>
    %2 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.ptr<f4E2M1FN, gmem, align<16>>
    %4 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %5 = "cute.get_layout"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %6 = "cute.make_shape"() : () -> !cute.shape<"(128,8)">
    %7 = "cute.make_stride"() : () -> !cute.stride<"(8,1)">
    %8 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(128,8):(8,1)">
    %9 = "cute.recast_layout"(%8) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"(128,4):(4,1)">
    %10 = "cute.recast_iter"(%3) : (!cute.ptr<f4E2M1FN, gmem, align<16>>) -> !cute.ptr<i8, gmem, align<16>>
    %11 = "cute.get_layout"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %12 = "cute.recast_layout"(%11) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %13 = "cute.make_view"(%10, %12) : (!cute.ptr<i8, gmem, align<16>>, !cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !memref_gmem_i8_6
    %14 = "cute.get_iter"(%13) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<16>>
    %15 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %16 = "cute.get_shape"(%15) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %17:3 = "cute.get_leaves"(%16) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %18 = "cute.to_int_tuple"(%17#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %19 = "cute.get_scalars"(%18) : (!cute.int_tuple<"?">) -> i32
    %20 = "cute.to_int_tuple"(%17#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.get_scalars"(%20) : (!cute.int_tuple<"?">) -> i32
    %22 = "cute.to_int_tuple"(%17#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %23 = "cute.get_scalars"(%22) : (!cute.int_tuple<"?">) -> i32
    %24 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %25 = "cute.get_shape"(%24) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %26:3 = "cute.get_leaves"(%25) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %27 = "cute.to_int_tuple"(%26#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %28 = "cute.get_scalars"(%27) : (!cute.int_tuple<"?">) -> i32
    %29 = "cute.to_int_tuple"(%26#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %30 = "cute.get_scalars"(%29) : (!cute.int_tuple<"?">) -> i32
    %31 = "cute.to_int_tuple"(%26#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %32 = "cute.get_scalars"(%31) : (!cute.int_tuple<"?">) -> i32
    %33 = "cute.make_shape"(%27, %29, %31) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %34 = "cute.make_identity_tensor"(%33) : (!cute.shape<"(?,?,?)">) -> !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %35 = "cute.get_iter"(%34) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %36 = "cute.deref_arith_tuple_iter"(%35) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %37:3 = "cute.get_leaves"(%36) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %38 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %39 = "cute.get_shape"(%38) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %40:3 = "cute.get_leaves"(%39) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %41 = "cute.to_int_tuple"(%40#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %42 = "cute.get_scalars"(%41) : (!cute.int_tuple<"?">) -> i32
    %43 = "cute.to_int_tuple"(%40#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %44 = "cute.get_scalars"(%43) : (!cute.int_tuple<"?">) -> i32
    %45 = "cute.to_int_tuple"(%40#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.get_scalars"(%45) : (!cute.int_tuple<"?">) -> i32
    %47 = "cute.size"(%8) <{mode = array<i32>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %48 = "cute.get_leaves"(%47) : (!cute.int_tuple<"1024">) -> !cute.int_tuple<"1024">
    %49 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %50 = "cute.get_shape"(%49) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %51:3 = "cute.get_leaves"(%50) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %52 = "cute.to_int_tuple"(%51#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %53 = "cute.get_scalars"(%52) : (!cute.int_tuple<"?">) -> i32
    %54 = "cute.to_int_tuple"(%51#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %55 = "cute.get_scalars"(%54) : (!cute.int_tuple<"?">) -> i32
    %56 = "cute.to_int_tuple"(%51#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %57 = "cute.get_scalars"(%56) : (!cute.int_tuple<"?">) -> i32
    %58 = "cute.size"(%9) <{mode = array<i32>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %59 = "cute.get_leaves"(%58) : (!cute.int_tuple<"512">) -> !cute.int_tuple<"512">
    %60 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %61 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %62 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %63:5 = "cute.get_scalars"(%62) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %64 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %65 = "arith.ceildivsi"(%63#1, %64) : (i32, i32) -> i32
    %66 = "cute.make_shape"(%63#0, %65, %63#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %67 = "cute.make_stride"(%63#3, %63#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %68 = "cute.make_layout"(%66, %67) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1024,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %69 = "cute.make_view"(%61, %68) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !memref_gmem_f32_
    %70 = "cute.get_iter"(%69) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %71 = "cute.get_iter"(%69) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %72 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %73 = "cute.get_iter"(%34) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %74 = "cute.get_layout"(%34) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %75:3 = "cute.get_scalars"(%74) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %76 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %77 = "arith.ceildivsi"(%75#1, %76) : (i32, i32) -> i32
    %78 = "cute.make_shape"(%75#0, %77, %75#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %79 = "cute.make_stride"() : () -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %80 = "cute.make_layout"(%78, %79) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1024,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %81 = "cute.make_view"(%73, %80) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %82 = "cute.get_iter"(%81) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %83 = "cute.deref_arith_tuple_iter"(%82) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %84:3 = "cute.get_leaves"(%83) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %85 = "cute.get_iter"(%81) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %86 = "cute.deref_arith_tuple_iter"(%85) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %87:3 = "cute.get_leaves"(%86) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %88 = "cute.make_tile"() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %89 = "cute.get_iter"(%13) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<16>>
    %90 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %91:5 = "cute.get_scalars"(%90) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %92 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %93 = "arith.ceildivsi"(%91#1, %92) : (i32, i32) -> i32
    %94 = "cute.make_shape"(%91#0, %93, %91#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %95 = "cute.make_stride"(%91#3, %91#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %96 = "cute.make_layout"(%94, %95) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %97 = "cute.make_view"(%89, %96) : (!cute.ptr<i8, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_i8_
    %98 = "cute.get_iter"(%97) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %99 = "cute.get_iter"(%97) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %100 = "cute.get_layout"(%69) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %101 = "cute.size"(%100) <{mode = array<i32: 1>}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?">
    %102 = "cute.get_leaves"(%101) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %103 = "cute.get_scalars"(%102) : (!cute.int_tuple<"?">) -> i32
    %104 = "cute.size"(%8) <{mode = array<i32: 0>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %105 = "cute.get_leaves"(%104) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %106 = "cute.get_layout"(%69) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %107 = "cute.get_layout"(%97) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %108 = "cute.get_layout"(%81) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %109 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %110 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %111 = "cuda.cast"(%110) : (i64) -> !cuda.stream
    %112 = "arith.extsi"(%109) : (i32) -> i64
    %113 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %114 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %115 = "cuda.launch_cfg.create"(%113, %114, %114, %112, %103, %114, %114, %111) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %116 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%115, %116) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %117 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%115, %117) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %118 = "cuda.launch_ex"(%115, %69, %97, %81, %19, %21, %23) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> !cuda.result
    %119 = "cuda.cast"(%118) : (!cuda.result) -> i32
    "cuda.return_if_error"(%119) : (i32) -> ()
    %120 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%120) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
