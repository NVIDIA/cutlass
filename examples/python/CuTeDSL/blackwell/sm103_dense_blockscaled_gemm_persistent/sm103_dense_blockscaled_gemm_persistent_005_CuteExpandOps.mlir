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
      %124 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %125 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %126 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %127 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %128 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %129 = "cute.deref_arith_tuple_iter"(%128) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %130:3 = "cute.get_leaves"(%129) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %131 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %132 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %133 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %134 = "cute.deref_arith_tuple_iter"(%133) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %135:3 = "cute.get_leaves"(%134) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %136 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %137 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %138 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %139 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %140 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %141 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %142 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %143 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %144 = "cute.make_coord"(%143) : (i32) -> !cute.coord<"(_,?)">
      %145 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %146 = "cute.crd2idx"(%144, %145) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %147 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %148 = "cute.add_offset"(%147, %146) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %149 = "cute.make_view"(%148) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_1
      %150 = "cute.get_iter"(%149) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %151 = "cute.get_iter"(%149) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %152 = "cute.make_coord"(%143) : (i32) -> !cute.coord<"(_,?)">
      %153 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %154 = "cute.crd2idx"(%152, %153) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %155 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %156 = "cute.add_offset"(%155, %154) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %157 = "cute.make_view"(%156) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_1
      %158 = "cute.get_iter"(%157) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %159 = "cute.get_iter"(%157) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %160 = "cute.make_coord"(%143) : (i32) -> !cute.coord<"(_,?)">
      %161 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %162 = "cute.crd2idx"(%160, %161) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %163 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %164 = "cute.add_offset"(%163, %162) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %165 = "cute.make_view"(%164) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %166 = "cute.get_iter"(%165) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %167 = "cute.deref_arith_tuple_iter"(%166) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %168:3 = "cute.get_leaves"(%167) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %169 = "cute.get_scalars"(%168#0) : (!cute.int_tuple<"?">) -> i32
      %170 = "cute.get_scalars"(%168#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %171 = "cute.get_scalars"(%168#2) : (!cute.int_tuple<"?">) -> i32
      %172 = "cute.get_iter"(%165) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %173 = "cute.deref_arith_tuple_iter"(%172) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %174:3 = "cute.get_leaves"(%173) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %175 = "cute.get_scalars"(%174#0) : (!cute.int_tuple<"?">) -> i32
      %176 = "cute.get_scalars"(%174#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %177 = "cute.get_scalars"(%174#2) : (!cute.int_tuple<"?">) -> i32
      %178 = "cute.get_iter"(%149) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %179 = "cute.make_view"(%178) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_2
      %180 = "cute.get_iter"(%179) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %181 = "cute.get_iter"(%157) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %182 = "cute.make_view"(%181) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_2
      %183 = "cute.get_iter"(%182) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %184 = "cute.get_iter"(%165) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %185 = "cute.make_view"(%184) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %186 = "cute.get_iter"(%185) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %187 = "cute.deref_arith_tuple_iter"(%186) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %188:3 = "cute.get_leaves"(%187) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %189 = "cute.get_scalars"(%188#0) : (!cute.int_tuple<"?">) -> i32
      %190 = "cute.get_scalars"(%188#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %191 = "cute.get_scalars"(%188#2) : (!cute.int_tuple<"?">) -> i32
      %192 = "cute.make_coord"(%142) : (i32) -> !cute.coord<"(?,_)">
      %193 = "cute.get_layout"(%179) : (!memref_gmem_f32_2) -> !cute.layout<"(128,8):(8,1)">
      %194 = "cute.crd2idx"(%192, %193) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %195 = "cute.get_iter"(%179) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %196 = "cute.add_offset"(%195, %194) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %197 = "cute.make_view"(%196) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_3
      %198 = "cute.get_iter"(%197) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %199 = "cute.get_iter"(%197) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %200 = "cute.make_coord"(%142) : (i32) -> !cute.coord<"(?,_)">
      %201 = "cute.get_layout"(%182) : (!memref_gmem_i8_2) -> !cute.layout<"(128,4):(4,1)">
      %202 = "cute.crd2idx"(%200, %201) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %203 = "cute.get_iter"(%182) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %204 = "cute.add_offset"(%203, %202) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %205 = "cute.make_view"(%204) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_3
      %206 = "cute.get_iter"(%205) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %207 = "cute.get_iter"(%205) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %208 = "cute.make_coord"(%142) : (i32) -> !cute.coord<"(?,_)">
      %209 = "cute.get_layout"(%185) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.layout<"(128,8):(8@1,1@1)">
      %210 = "cute.crd2idx"(%208, %209) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %211 = "cute.get_iter"(%185) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %212 = "cute.add_offset"(%211, %210) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %213 = "cute.make_view"(%212) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %214 = "cute.get_iter"(%213) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %215 = "cute.deref_arith_tuple_iter"(%214) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %216:3 = "cute.get_leaves"(%215) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %217 = "cute.get_scalars"(%216#0) : (!cute.int_tuple<"?">) -> i32
      %218 = "cute.get_scalars"(%216#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %219 = "cute.get_scalars"(%216#2) : (!cute.int_tuple<"?">) -> i32
      %220 = "cute.get_iter"(%213) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %221 = "cute.deref_arith_tuple_iter"(%220) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %222:3 = "cute.get_leaves"(%221) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %223 = "cute.get_scalars"(%222#0) : (!cute.int_tuple<"?">) -> i32
      %224 = "cute.get_scalars"(%222#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %225 = "cute.get_scalars"(%222#2) : (!cute.int_tuple<"?">) -> i32
      %226 = "cute.make_coord"() : () -> !cute.coord<"0">
      %227 = "cute.get_layout"(%213) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.layout<"(8):(1@1)">
      %228 = "cute.crd2idx"(%226, %227) : (!cute.coord<"0">, !cute.layout<"(8):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %229 = "cute.get_iter"(%213) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %230 = "cute.add_offset"(%229, %228) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %231 = "cute.make_view"(%230) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %232 = "cute.get_iter"(%231) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %233 = "cute.deref_arith_tuple_iter"(%232) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %234:3 = "cute.get_leaves"(%233) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %235 = "cute.get_scalars"(%234#0) : (!cute.int_tuple<"?">) -> i32
      %236 = "cute.get_scalars"(%234#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %237 = "cute.get_scalars"(%234#2) : (!cute.int_tuple<"?">) -> i32
      %238 = "cute.get_iter"(%231) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %239 = "cute.deref_arith_tuple_iter"(%238) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %240:3 = "cute.get_leaves"(%239) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %241 = "cute.get_scalars"(%240#0) : (!cute.int_tuple<"?">) -> i32
      %242 = "cute.get_scalars"(%240#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %243 = "cute.get_scalars"(%240#2) : (!cute.int_tuple<"?">) -> i32
      %244 = "cute.get_iter"(%231) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %245 = "cute.deref_arith_tuple_iter"(%244) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %246:3 = "cute.get_leaves"(%245) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %247 = "cute.get_scalars"(%246#0) : (!cute.int_tuple<"?">) -> i32
      %248 = "cute.get_scalars"(%246#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %249 = "cute.get_scalars"(%246#2) : (!cute.int_tuple<"?">) -> i32
      %250 = "cute.make_coord"(%246#0, %246#1, %246#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %251 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %252:3 = "cute.get_scalars"(%250) : (!cute.coord<"(?,?{div=8},?)">) -> (i32, i32, i32)
      %253:3 = "cute.get_scalars"(%251) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %254 = "arith.constant"() <{value = true}> : () -> i1
      %255 = "arith.cmpi"(%252#0, %253#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %256 = "arith.andi"(%254, %255) : (i1, i1) -> i1
      %257 = "arith.cmpi"(%252#1, %253#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %258 = "arith.andi"(%256, %257) : (i1, i1) -> i1
      %259 = "arith.cmpi"(%252#2, %253#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %260 = "arith.andi"(%258, %259) : (i1, i1) -> i1
      "scf.if"(%260) ({
        %261 = "cute.get_shape"(%124) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %262:2 = "cute.get_leaves"(%261) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %263 = "cute.get_shape"(%124) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %264:2 = "cute.get_leaves"(%263) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %265 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
        %266 = "cute.memref.alloca"(%265) : (!cute.layout<"8:1">) -> !memref_rmem_f32_
        %267 = "cute.get_iter"(%266) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %268 = "cute.get_iter"(%266) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %269 = "cute.get_shape"(%125) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %270:2 = "cute.get_leaves"(%269) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %271 = "cute.get_shape"(%125) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %272:2 = "cute.get_leaves"(%271) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %273 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"4:1">
        %274 = "cute.memref.alloca"(%273) : (!cute.layout<"4:1">) -> !memref_rmem_i8_
        %275 = "cute.get_iter"(%274) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %276 = "cute.get_iter"(%274) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %277 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %278 = "cute.get_layout"(%197) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %279 = "cute.get_shape"(%278) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %280 = "cute.get_leaves"(%279) : (!cute.shape<"(8)">) -> !cute.shape<"8">
        %281 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %282 = "cute.get_shape"(%281) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %283 = "cute.get_leaves"(%282) : (!cute.shape<"8">) -> !cute.shape<"8">
        %284 = "cute.get_layout"(%197) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %285 = "cute.make_shape"() : () -> !cute.shape<"1">
        %286 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %287 = "cute.append_to_rank"(%284, %286) <{rank = 2 : si32}> : (!cute.layout<"(8):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %288 = "cute.make_view"(%199, %287) : (!cute.ptr<f32, gmem>, !cute.layout<"(8,1):(1,0)">) -> !memref_gmem_f32_4
        %289 = "cute.get_iter"(%288) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %290 = "cute.get_layout"(%288) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %291 = "cute.get_shape"(%290) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %292:2 = "cute.get_leaves"(%291) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %293 = "cute.get_layout"(%288) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %294 = "cute.get_shape"(%293) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %295:2 = "cute.get_leaves"(%294) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %296 = "cute.get_iter"(%288) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %297 = "cute.make_view"(%296) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_5
        %298 = "cute.get_iter"(%297) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %299 = "cute.get_iter"(%297) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %300 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %301 = "cute.make_shape"() : () -> !cute.shape<"1">
        %302 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %303 = "cute.append_to_rank"(%300, %302) <{rank = 2 : si32}> : (!cute.layout<"8:1">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %304 = "cute.make_view"(%268, %303) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8,1):(1,0)">) -> !memref_rmem_f32_1
        %305 = "cute.get_iter"(%304) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %306 = "cute.get_layout"(%304) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %307 = "cute.get_shape"(%306) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %308:2 = "cute.get_leaves"(%307) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %309 = "cute.get_layout"(%304) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %310 = "cute.get_shape"(%309) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %311:2 = "cute.get_leaves"(%310) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %312 = "cute.get_iter"(%304) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %313 = "cute.make_view"(%312) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %314 = "cute.get_iter"(%313) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %315 = "cute.get_iter"(%313) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %316 = "cute.get_layout"(%297) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %317 = "cute.get_shape"(%316) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %318:2 = "cute.get_leaves"(%317) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %319 = "cute.get_layout"(%313) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %320 = "cute.get_shape"(%319) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %321:2 = "cute.get_leaves"(%320) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %322 = "cute.get_layout"(%297) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %323 = "cute.size"(%322) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %324 = "cute.get_leaves"(%323) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %325 = "cute.get_layout"(%313) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %326 = "cute.size"(%325) <{mode = array<i32: 1>}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %327 = "cute.get_leaves"(%326) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %328 = "cute.static"() : () -> !cute.layout<"1:0">
        %329 = "cute.get_iter"(%297) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %330 = "cute.get_iter"(%313) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %331 = "cute.get_layout"(%297) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %332 = "cute.get_layout"(%313) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %333 = "cute.append_to_rank"(%331, %328) <{rank = 2 : si32}> : (!cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1)):(1,(0))">
        %334 = "cute.append_to_rank"(%332, %328) <{rank = 2 : si32}> : (!cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(8,(1)):(1,(0))">
        %335 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1))):(1,((0)))">
        %336 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,((1))):(1,((0)))">
        %337 = "cute.size"(%335) <{mode = array<i32: 1>}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %338 = "cute.get_scalars"(%337) : (!cute.int_tuple<"1">) -> i32
        %339 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %340 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%339, %338, %340) ({
        ^bb0(%arg9: i32):
          %469 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %470 = "cute.get_scalars"(%469) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %471 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
          %472 = "cute.crd2idx"(%469, %335) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %473 = "cute.add_offset"(%329, %472) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %474 = "cute.make_view"(%473, %471) : (!cute.ptr<f32, gmem>, !cute.layout<"(8):(1)">) -> !memref_gmem_f32_3
          %475 = "cute.get_scalars"(%469) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %476 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8):(1)">
          %477 = "cute.crd2idx"(%469, %336) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %478 = "cute.add_offset"(%330, %477) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %479 = "cute.make_view"(%478, %476) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_f32_3
          %480 = "cute.get_iter"(%474) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %481 = "cute.get_iter"(%479) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem, align<32>>
          %482 = "builtin.unrealized_conversion_cast"(%480) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %483 = "builtin.unrealized_conversion_cast"(%481) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %484 = "llvm.load"(%482) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%484, %483) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %485 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %486 = "cute.add_offset"(%480, %485) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %487 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %488 = "cute.add_offset"(%481, %487) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %489 = "builtin.unrealized_conversion_cast"(%486) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %490 = "builtin.unrealized_conversion_cast"(%488) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %491 = "llvm.load"(%489) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%491, %490) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %492 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %493 = "cute.add_offset"(%480, %492) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %494 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %495 = "cute.add_offset"(%481, %494) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %496 = "builtin.unrealized_conversion_cast"(%493) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %497 = "builtin.unrealized_conversion_cast"(%495) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %498 = "llvm.load"(%496) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%498, %497) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %499 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %500 = "cute.add_offset"(%480, %499) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %501 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %502 = "cute.add_offset"(%481, %501) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %503 = "builtin.unrealized_conversion_cast"(%500) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %504 = "builtin.unrealized_conversion_cast"(%502) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %505 = "llvm.load"(%503) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%505, %504) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %506 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
          %507 = "cute.add_offset"(%480, %506) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %508 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
          %509 = "cute.add_offset"(%481, %508) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %510 = "builtin.unrealized_conversion_cast"(%507) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %511 = "builtin.unrealized_conversion_cast"(%509) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %512 = "llvm.load"(%510) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%512, %511) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %513 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
          %514 = "cute.add_offset"(%480, %513) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %515 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"5">
          %516 = "cute.add_offset"(%481, %515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %517 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %518 = "builtin.unrealized_conversion_cast"(%516) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %519 = "llvm.load"(%517) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%519, %518) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %520 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
          %521 = "cute.add_offset"(%480, %520) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %522 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"6">
          %523 = "cute.add_offset"(%481, %522) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %524 = "builtin.unrealized_conversion_cast"(%521) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %525 = "builtin.unrealized_conversion_cast"(%523) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %526 = "llvm.load"(%524) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%526, %525) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %527 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
          %528 = "cute.add_offset"(%480, %527) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %529 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"7">
          %530 = "cute.add_offset"(%481, %529) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %531 = "builtin.unrealized_conversion_cast"(%528) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %532 = "builtin.unrealized_conversion_cast"(%530) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %533 = "llvm.load"(%531) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%533, %532) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %341 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %342 = "cute.get_shape"(%341) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %343 = "cute.get_leaves"(%342) : (!cute.shape<"8">) -> !cute.shape<"8">
        %344 = "cute.memref.load_vec"(%266) : (!memref_rmem_f32_) -> vector<8xf32>
        %345 = "cute.get_layout"(%266) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %346 = "cute.get_shape"(%345) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %347 = "cute.get_leaves"(%346) : (!cute.shape<"8">) -> !cute.shape<"8">
        %348 = "nvgpu.cvt_fptrunc"(%344) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<8xf32>) -> vector<8xf4E2M1FN>
        %349 = "cute.make_shape"() : () -> !cute.shape<"8">
        %350 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"8:1">
        %351 = "cute.recast_layout"(%350) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %352 = "cute.get_shape"(%351) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %353 = "cute.get_leaves"(%352) : (!cute.shape<"4">) -> !cute.shape<"4">
        %354 = "builtin.unrealized_conversion_cast"(%348) : (vector<8xf4E2M1FN>) -> vector<8xi4>
        %355 = "vector.bitcast"(%354) : (vector<8xi4>) -> vector<4xi8>
        %356 = "cute.get_layout"(%274) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %357 = "cute.get_shape"(%356) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %358 = "cute.get_leaves"(%357) : (!cute.shape<"4">) -> !cute.shape<"4">
        %359 = "cute.get_layout"(%274) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %360 = "cute.get_shape"(%359) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %361 = "cute.get_leaves"(%360) : (!cute.shape<"4">) -> !cute.shape<"4">
        %362 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %363 = "cute.size"(%362) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %364 = "cute.get_leaves"(%363) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %365 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %366 = "cute.size"(%365) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %367 = "cute.get_leaves"(%366) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        "cute.memref.store_vec"(%355, %274) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %368 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %369 = "cute.get_layout"(%274) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %370 = "cute.get_shape"(%369) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %371 = "cute.get_leaves"(%370) : (!cute.shape<"4">) -> !cute.shape<"4">
        %372 = "cute.get_layout"(%205) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %373 = "cute.get_shape"(%372) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %374 = "cute.get_leaves"(%373) : (!cute.shape<"(4)">) -> !cute.shape<"4">
        %375 = "cute.get_layout"(%274) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %376 = "cute.make_shape"() : () -> !cute.shape<"1">
        %377 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %378 = "cute.append_to_rank"(%375, %377) <{rank = 2 : si32}> : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %379 = "cute.make_view"(%276, %378) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_i8_1
        %380 = "cute.get_iter"(%379) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %381 = "cute.get_layout"(%379) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %382 = "cute.get_shape"(%381) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %383:2 = "cute.get_leaves"(%382) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %384 = "cute.get_layout"(%379) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %385 = "cute.get_shape"(%384) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %386:2 = "cute.get_leaves"(%385) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %387 = "cute.get_iter"(%379) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %388 = "cute.make_view"(%387) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %389 = "cute.get_iter"(%388) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %390 = "cute.get_iter"(%388) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %391 = "cute.get_layout"(%205) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %392 = "cute.make_shape"() : () -> !cute.shape<"1">
        %393 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"1:0">
        %394 = "cute.append_to_rank"(%391, %393) <{rank = 2 : si32}> : (!cute.layout<"(4):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %395 = "cute.make_view"(%207, %394) : (!cute.ptr<i8, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_i8_4
        %396 = "cute.get_iter"(%395) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %397 = "cute.get_layout"(%395) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %398 = "cute.get_shape"(%397) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %399:2 = "cute.get_leaves"(%398) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %400 = "cute.get_layout"(%395) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %401 = "cute.get_shape"(%400) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %402:2 = "cute.get_leaves"(%401) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %403 = "cute.get_iter"(%395) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %404 = "cute.make_view"(%403) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_5
        %405 = "cute.get_iter"(%404) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %406 = "cute.get_iter"(%404) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %407 = "cute.get_layout"(%388) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %408 = "cute.get_shape"(%407) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %409:2 = "cute.get_leaves"(%408) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %410 = "cute.get_layout"(%404) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %411 = "cute.get_shape"(%410) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %412:2 = "cute.get_leaves"(%411) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %413 = "cute.get_layout"(%388) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %414 = "cute.size"(%413) <{mode = array<i32: 1>}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %415 = "cute.get_leaves"(%414) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %416 = "cute.get_layout"(%404) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %417 = "cute.size"(%416) <{mode = array<i32: 1>}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %418 = "cute.get_leaves"(%417) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %419 = "cute.static"() : () -> !cute.layout<"1:0">
        %420 = "cute.get_iter"(%388) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %421 = "cute.get_iter"(%404) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %422 = "cute.get_layout"(%388) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %423 = "cute.get_layout"(%404) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %424 = "cute.append_to_rank"(%422, %419) <{rank = 2 : si32}> : (!cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(4,(1)):(1,(0))">
        %425 = "cute.append_to_rank"(%423, %419) <{rank = 2 : si32}> : (!cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">) -> !cute.layout<"(4,(1)):(1,(0))">
        %426 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,((1))):(1,((0)))">
        %427 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4,((1))):(1,((0)))">
        %428 = "cute.size"(%426) <{mode = array<i32: 1>}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %429 = "cute.get_scalars"(%428) : (!cute.int_tuple<"1">) -> i32
        %430 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %431 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%430, %429, %431) ({
        ^bb0(%arg8: i32):
          %432 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"(_,?)">
          %433 = "cute.get_scalars"(%432) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %434 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4):(1)">
          %435 = "cute.crd2idx"(%432, %426) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %436 = "cute.add_offset"(%420, %435) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %437 = "cute.make_view"(%436, %434) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_i8_3
          %438 = "cute.get_scalars"(%432) <{only_dynamic}> : (!cute.coord<"(_,?)">) -> i32
          %439 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(4):(1)">
          %440 = "cute.crd2idx"(%432, %427) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %441 = "cute.add_offset"(%421, %440) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %442 = "cute.make_view"(%441, %439) : (!cute.ptr<i8, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_i8_3
          %443 = "cute.get_iter"(%437) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
          %444 = "cute.get_iter"(%442) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
          %445 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
          %446 = "builtin.unrealized_conversion_cast"(%444) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %447 = "llvm.load"(%445) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%447, %446) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %448 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %449 = "cute.add_offset"(%443, %448) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %450 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"1">
          %451 = "cute.add_offset"(%444, %450) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %452 = "builtin.unrealized_conversion_cast"(%449) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %453 = "builtin.unrealized_conversion_cast"(%451) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %454 = "llvm.load"(%452) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%454, %453) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %455 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %456 = "cute.add_offset"(%443, %455) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %457 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"2">
          %458 = "cute.add_offset"(%444, %457) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %459 = "builtin.unrealized_conversion_cast"(%456) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
          %460 = "builtin.unrealized_conversion_cast"(%458) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %461 = "llvm.load"(%459) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%461, %460) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %462 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %463 = "cute.add_offset"(%443, %462) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %464 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"3">
          %465 = "cute.add_offset"(%444, %464) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %466 = "builtin.unrealized_conversion_cast"(%463) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %467 = "builtin.unrealized_conversion_cast"(%465) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %468 = "llvm.load"(%466) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%468, %467) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
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
    %34 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %35 = "cute.make_stride"() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %36 = "cute.make_layout"(%33, %35) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %37 = "cute.make_view"(%34, %36) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %38 = "cute.get_iter"(%37) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %39 = "cute.deref_arith_tuple_iter"(%38) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %40:3 = "cute.get_leaves"(%39) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %41 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %42 = "cute.get_shape"(%41) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %43:3 = "cute.get_leaves"(%42) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %44 = "cute.to_int_tuple"(%43#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %45 = "cute.get_scalars"(%44) : (!cute.int_tuple<"?">) -> i32
    %46 = "cute.to_int_tuple"(%43#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %47 = "cute.get_scalars"(%46) : (!cute.int_tuple<"?">) -> i32
    %48 = "cute.to_int_tuple"(%43#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %49 = "cute.get_scalars"(%48) : (!cute.int_tuple<"?">) -> i32
    %50 = "cute.size"(%8) <{mode = array<i32>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %51 = "cute.get_leaves"(%50) : (!cute.int_tuple<"1024">) -> !cute.int_tuple<"1024">
    %52 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %53 = "cute.get_shape"(%52) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %54:3 = "cute.get_leaves"(%53) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %55 = "cute.to_int_tuple"(%54#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %56 = "cute.get_scalars"(%55) : (!cute.int_tuple<"?">) -> i32
    %57 = "cute.to_int_tuple"(%54#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %58 = "cute.get_scalars"(%57) : (!cute.int_tuple<"?">) -> i32
    %59 = "cute.to_int_tuple"(%54#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %60 = "cute.get_scalars"(%59) : (!cute.int_tuple<"?">) -> i32
    %61 = "cute.size"(%9) <{mode = array<i32>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %62 = "cute.get_leaves"(%61) : (!cute.int_tuple<"512">) -> !cute.int_tuple<"512">
    %63 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %64 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %65 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %66:5 = "cute.get_scalars"(%65) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %67 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %68 = "arith.ceildivsi"(%66#1, %67) : (i32, i32) -> i32
    %69 = "cute.make_shape"(%66#0, %68, %66#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %70 = "cute.make_stride"(%66#3, %66#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %71 = "cute.make_layout"(%69, %70) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1024,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %72 = "cute.make_view"(%64, %71) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !memref_gmem_f32_
    %73 = "cute.get_iter"(%72) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %74 = "cute.get_iter"(%72) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %75 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %76 = "cute.get_iter"(%37) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %77 = "cute.get_layout"(%37) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %78:3 = "cute.get_scalars"(%77) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %79 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %80 = "arith.ceildivsi"(%78#1, %79) : (i32, i32) -> i32
    %81 = "cute.make_shape"(%78#0, %80, %78#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %82 = "cute.make_stride"() : () -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %83 = "cute.make_layout"(%81, %82) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1024,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %84 = "cute.make_view"(%76, %83) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %85 = "cute.get_iter"(%84) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %86 = "cute.deref_arith_tuple_iter"(%85) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %87:3 = "cute.get_leaves"(%86) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %88 = "cute.get_iter"(%84) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %89 = "cute.deref_arith_tuple_iter"(%88) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %90:3 = "cute.get_leaves"(%89) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %91 = "cute.make_tile"() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %92 = "cute.get_iter"(%13) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<16>>
    %93 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %94:5 = "cute.get_scalars"(%93) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %95 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %96 = "arith.ceildivsi"(%94#1, %95) : (i32, i32) -> i32
    %97 = "cute.make_shape"(%94#0, %96, %94#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %98 = "cute.make_stride"(%94#3, %94#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %99 = "cute.make_layout"(%97, %98) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %100 = "cute.make_view"(%92, %99) : (!cute.ptr<i8, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_i8_
    %101 = "cute.get_iter"(%100) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %102 = "cute.get_iter"(%100) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %103 = "cute.get_layout"(%72) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %104 = "cute.size"(%103) <{mode = array<i32: 1>}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?">
    %105 = "cute.get_leaves"(%104) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %106 = "cute.get_scalars"(%105) : (!cute.int_tuple<"?">) -> i32
    %107 = "cute.size"(%8) <{mode = array<i32: 0>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %108 = "cute.get_leaves"(%107) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %109 = "cute.get_layout"(%72) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %110 = "cute.get_layout"(%100) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %111 = "cute.get_layout"(%84) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %112 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %113 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %114 = "cuda.cast"(%113) : (i64) -> !cuda.stream
    %115 = "arith.extsi"(%112) : (i32) -> i64
    %116 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %117 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %118 = "cuda.launch_cfg.create"(%116, %117, %117, %115, %106, %117, %117, %114) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %119 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%118, %119) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %120 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%118, %120) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %121 = "cuda.launch_ex"(%118, %72, %100, %84, %19, %21, %23) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> !cuda.result
    %122 = "cuda.cast"(%121) : (!cuda.result) -> i32
    "cuda.return_if_error"(%122) : (i32) -> ()
    %123 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%123) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
